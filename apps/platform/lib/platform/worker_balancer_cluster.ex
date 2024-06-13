defmodule Platform.WorkerBalancerCluster do
  use GenServer
  import Ex2ms
  alias Phoenix.PubSub
  alias Platform.WorkerBalancer

  @table_name :worker_balancer_cluster

  def table_name(), do: @table_name

  def dump() do
    :ets.tab2list(@table_name)
  end

  def lock(id, node) do
    case :rpc.call(id, node, WorkerBalancer, :lock, [id]) do
      true -> true
      _ -> false
    end
  end

  def get_worker(model) do
    node_self = Node.self()

    match_spec =
      fun do
        {_id, ^model, :free, node} = worker when node != ^node_self -> worker
      end

    case :ets.select(@table_name, match_spec) do
      [_ | _] = workers ->
        {id, _model, _status, node} = Enum.random(workers)

        case lock(id, node) do
          true -> {:ok, id}
          false -> {:error, :lock_failed}
        end

      [] ->
        {:error, :no_workers}
    end
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    :ets.new(
      @table_name,
      [
        :set,
        :public,
        :named_table,
        {:read_concurrency, true}
      ]
    )

    PubSub.subscribe(Platform.PubSub, WorkerBalancer.pubsub_topic())
    :net_kernel.monitor_nodes(true)

    {:ok, %{}}
  end

  @impl true
  def terminate(_reason, _state) do
    :ets.delete(@table_name)

    :ok
  end

  @impl true
  def handle_info({:agg, workers, node}, state) do
    new_workers =
      Enum.map(workers, fn {id, model, status} ->
        {id, model, status, node}
      end)

    :ets.insert(@table_name, new_workers)

    {:noreply, state}
  end

  @impl true
  def handle_info({:nodeup, _node}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    match_spec =
      fun do
        {_, _, _, ^node} -> true
      end

    :ets.select_delete(@table_name, match_spec)

    {:noreply, state}
  end
end
