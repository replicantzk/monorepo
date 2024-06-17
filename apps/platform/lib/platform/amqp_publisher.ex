defmodule Platform.AMQPPublisher do
  use GenServer
  use AMQP
  alias Platform.PartitionSupervisorAMQPPublisher

  @amqp_channel :req_chann
  @amqp_exchange "exchange_inference"

  def publish(payload) do
    n_partitions = Application.fetch_env!(:platform, :amqp_pub_partitions)
    key = :rand.uniform(n_partitions)

    GenServer.call(
      {
        :via,
        PartitionSupervisor,
        {PartitionSupervisorAMQPPublisher, key}
      },
      {:publish, payload}
    )
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(_opts) do
    {:ok, chan} = AMQP.Application.get_channel(@amqp_channel)

    {:ok, %{chan: chan}}
  end

  @impl true
  def handle_call({:publish, payload}, _from, %{chan: chan} = state) do
    {:reply, publish_queue(chan, payload), state}
  end

  def publish_queue(chan, request) do
    with model when is_binary(model) <- get_in(request, ["params", "model"]),
         {:ok, payload} <- Jason.encode(request),
         :ok <-
           AMQP.Basic.publish(
             chan,
             @amqp_exchange,
             model,
             payload,
             mandatory: true
           ) do
      :ok
    else
      nil -> {:error, :model_not_found}
      {:error, reason} -> {:error, reason}
    end
  end
end
