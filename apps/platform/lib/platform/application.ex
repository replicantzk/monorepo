defmodule Platform.Application do
  @moduledoc false
  use Application
  alias Platform.ConnectionLimiter
  alias PlatformWeb.Plugs.BalanceChecker
  alias PlatformWeb.Plugs.RateLimiter
  alias PlatformWeb.Plugs.TokenChecker

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{})

    children =
      [
        PlatformWeb.Telemetry,
        Platform.Repo,
        {DNSCluster, query: Application.get_env(:platform, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Platform.PubSub},
        {Finch, name: Platform.Finch},
        PlatformWeb.Endpoint,
        {Platform.AMQPConsumerSupervisor, []},
        {PartitionSupervisor,
         child_spec: Platform.AMQPPublisher, name: Platform.PartitionSupervisorAMQPPublisher},
        {Platform.WorkerBalancerCluster, []},
        {Platform.WorkerBalancer, []}
      ] ++ cache_specs()

    opts = [strategy: :one_for_one, name: Platform.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PlatformWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def cache_specs() do
    keys = [
      ConnectionLimiter.cache_name(),
      RateLimiter.cache_name(),
      TokenChecker.cache_name(),
      BalanceChecker.cache_name()
    ]

    Enum.map(keys, fn key ->
      Supervisor.child_spec(
        {Cachex, key},
        id: key
      )
    end)
  end
end
