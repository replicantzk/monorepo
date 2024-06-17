defmodule Platform.AMQPConsumer do
  use GenServer
  use AMQP
  alias Platform.WorkerBalancer
  alias PlatformWeb.Endpoint

  @amqp_channel :req_chann
  @amqp_exchange "exchange_inference"
  @worker_topic "request"

  def inference_topic(worker_id) do
    "inference:#{worker_id}"
  end

  def start_link([model: _model] = opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl true
  def init(model: model) do
    {:ok, chan} = AMQP.Application.get_channel(@amqp_channel)
    {:ok, _queue_info} = setup_queue(chan, model)

    prefetch_count = Application.fetch_env!(:platform, :amqp_prefetch_count)
    :ok = Basic.qos(chan, prefetch_count: prefetch_count, global: true)
    {:ok, _consumer_tag} = Basic.consume(chan, model)

    {:ok, chan}
  end

  @impl true
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info(
        {:basic_deliver, payload,
         %{routing_key: model, delivery_tag: delivery_tag, redelivered: _redelivered}},
        chan
      ) do
    with {:ok, worker_id} <- WorkerBalancer.get_worker(model),
         {:ok, request} <- Jason.decode(payload),
         {:ok, request_id} <- Map.fetch(request, "uuid"),
         {:ok, params} <- Map.fetch(request, "params"),
         :ok <- Basic.ack(chan, delivery_tag) do
      push(worker_id, request_id, params)
    else
      _ -> Basic.nack(chan, delivery_tag, requeue: true)
    end

    {:noreply, chan}
  end

  def setup_queue(chan, key) do
    with {:ok, queue_info} <-
           Queue.declare(chan, key,
             auto_delete: true,
             arguments: [
               {"x-expires", :long, Application.fetch_env!(:platform, :request_timeout)}
             ]
           ),
         :ok <- Exchange.topic(chan, @amqp_exchange),
         :ok <- Queue.bind(chan, key, @amqp_exchange, routing_key: key) do
      {:ok, queue_info}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp push(worker_id, request_id, params) do
    Endpoint.broadcast(
      inference_topic(worker_id),
      @worker_topic,
      %{id: request_id, params: params}
    )
  end
end
