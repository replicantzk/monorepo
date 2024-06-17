defmodule Platform.AMQPConsumerSupervisor do
  use Supervisor
  alias Platform.AMQPConsumer
  alias Platform.Model

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    consumers_per_model = Application.fetch_env!(:platform, :amqp_cons_per_model)

    children =
      Enum.reduce(Model.supported_models_keys(), [], fn model, acc ->
        Enum.map(1..consumers_per_model, fn n ->
          Supervisor.child_spec(
            {
              AMQPConsumer,
              [model: model]
            },
            id: {AMQPConsumer, "#{model}_#{n}"}
          )
        end) ++ acc
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
