defmodule Platform.Application do
  @moduledoc false
  use Application
  alias Platform.AMQPConsumer
  alias Platform.Model

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{})

    children = [
      PlatformWeb.Telemetry,
      Platform.Repo,
      {DNSCluster, query: Application.get_env(:platform, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Platform.PubSub},
      {Finch, name: Platform.Finch},
      PlatformWeb.Endpoint,
      {Task.Supervisor, name: Platform.TaskSupervisor},
      {Platform.ChannelMonitor, name: :worker},
      {Platform.WorkerBalancer, []},
      {Platform.WorkerBalancerCluster, []},
      {Registry, keys: :duplicate, name: Platform.RegistryAMQPConsumer},
      {DynamicSupervisor, strategy: :one_for_one, name: Platform.DynamicSupervisorAMQPConsumer},
      {PartitionSupervisor,
       child_spec: Platform.AMQPPublisher, name: Platform.PartitionSupervisorAMQPPublisher},
      Supervisor.child_spec({Cachex, :connection_limiter}, id: :connection_limiter),
      Supervisor.child_spec({Cachex, :rate_limiter}, id: :rate_limiter),
      Supervisor.child_spec({Cachex, :tokens}, id: :tokens),
      Supervisor.child_spec({Cachex, :balances}, id: :balances)
    ]

    opts = [strategy: :one_for_one, name: Platform.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, _} = success ->
        start_consumers()
        success

      other ->
        other
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    PlatformWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def start_consumers() do
    Enum.each(Model.supported_models_keys(), fn model ->
      AMQPConsumer.start(model)
    end)
  end
end
