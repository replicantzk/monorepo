defmodule Platform.AMQPConsumer do
  use GenServer
  use AMQP
  alias Platform.DynamicSupervisorAMQPConsumer
  alias Platform.RegistryAMQPConsumer
  alias Platform.WorkerBalancer
  alias PlatformWeb.Endpoint

  @amqp_channel :req_chann
  @amqp_exchange "exchange_inference"
  @worker_topic "request"

  def start(model) do
    consumers = Registry.lookup(RegistryAMQPConsumer, model)
    n_consumers = Application.fetch_env!(:platform, :amqp_consumers_per_model)
    diff = n_consumers - length(consumers)

    if diff > 0 do
      1..diff
      |> Enum.map(fn _ ->
        DynamicSupervisor.start_child(
          DynamicSupervisorAMQPConsumer,
          {__MODULE__, [model: model]}
        )
      end)
    end
  end

  def stop(model) do
    consumers = Registry.lookup(RegistryAMQPConsumer, model)

    Enum.each(consumers, fn {pid, _value} ->
      DynamicSupervisor.terminate_child(DynamicSupervisorAMQPConsumer, pid)
    end)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl true
  def init(opts) do
    model = Keyword.fetch!(opts, :model)
    Registry.register(RegistryAMQPConsumer, model, self())

    {:ok, chan} = AMQP.Application.get_channel(@amqp_channel)

    :ok = setup_queue(chan, model)

    # Limit unacknowledged messages to 1
    :ok = Basic.qos(chan, prefetch_count: 1, global: true)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, model)

    {:ok, chan}
  end

  @impl true
  def terminate(_reason, _state) do
    models = Registry.keys(RegistryAMQPConsumer, self())

    Enum.each(models, fn model ->
      stop(model)
    end)
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
    case WorkerBalancer.get_worker(model) do
      {:ok, worker_id} ->
        request = Jason.decode!(payload)
        request_id = Map.fetch!(request, "id")
        params = Map.fetch!(request, "params")
        Basic.ack(chan, delivery_tag)
        push(worker_id, request_id, params)

      {:error, _reason} ->
        Basic.nack(chan, delivery_tag, requeue: true)
    end

    {:noreply, chan}
  end

  def setup_queue(chan, key) do
    {:ok, _} =
      Queue.declare(chan, key,
        auto_delete: true,
        arguments: [
          {"x-expires", :long, Application.fetch_env!(:platform, :request_timeout)}
        ]
      )

    :ok = Exchange.topic(chan, @amqp_exchange)
    :ok = Queue.bind(chan, key, @amqp_exchange, routing_key: key)

    :ok
  end

  defp push(worker_id, request_id, params) do
    Endpoint.broadcast(
      "inference:#{worker_id}",
      @worker_topic,
      %{id: request_id, params: params}
    )
  end
end
