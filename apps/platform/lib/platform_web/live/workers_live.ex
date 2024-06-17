defmodule PlatformWeb.WorkersLive do
  use PlatformWeb, :live_view
  alias Platform.Model
  alias Platform.WorkerBalancer
  alias Platform.WorkerBalancerCluster

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <h1 class="text-2xl font-semibold">Workers</h1>
      <%= for model <- Model.supported_models_keys() do %>
        <% workers = Map.get(@workers_by_model, model) %>
        <div class="node-group mb-4">
          <%= if workers do %>
            <h3 class="text-lg font-bold mb-2"><%= model %>(<%= length(workers) %>)</h3>
            <div class="flex flex-wrap">
              <%= for {id, status, node} <- workers do %>
                <div
                  class={"w-8 h-8 bg-gray-300 aspect-w-1 aspect-h-1 " <> "#{status_color(status)} mr-2 mb-2"}
                  title={"id: #{id}, status: #{status}, node: #{node}"}
                >
                </div>
              <% end %>
            </div>
          <% else %>
            <h3 class="text-lg font-bold mb-2"><%= model %></h3>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp status_base(), do: ""
  defp status_color(:free), do: status_base() <> "bg-green-400"
  defp status_color(:lock), do: status_base() <> "bg-red-400"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Platform.PubSub, WorkerBalancer.pubsub_topic())
      :net_kernel.monitor_nodes(true)
    end

    workers_ets =
      WorkerBalancer.table_name()
      |> :ets.tab2list()
      |> Enum.map(fn {id, model, status} ->
        {id, model, status, Node.self()}
      end)
    workers_cluster_ets = :ets.tab2list(WorkerBalancerCluster.table_name())
    workers_combined_ets = workers_ets ++ workers_cluster_ets

    workers =
      Enum.reduce(workers_combined_ets, %{}, fn {id, model, status, node}, acc ->
        Map.update(acc, node, [{id, model, status, node}], fn models ->
          [{id, model, status, node}] ++ models
        end)
      end)

    {:ok,
     socket
     |> assign(workers: workers)
     |> assign(workers_local: workers)
     |> assign(workers_by_model: get_workers_by_model(workers))}
  end

  @impl true
  def handle_info({:nodeup, _node}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:nodedown, node}, socket) do
    {:noreply,
     assign(socket,
       workers: Map.delete(socket.assigns.workers, node)
     )}
  end

  @impl true
  def handle_info({:agg, node_workers, node}, socket) do
    workers =
      socket.assigns.workers
      |> Map.put(node, node_workers)

    {:noreply,
     socket
     |> assign(workers: workers)
     |> assign(workers_by_model: get_workers_by_model(workers))}
  end

  defp get_workers_by_model(workers) do
    Enum.reduce(workers, %{}, fn {_node, worker_list}, acc ->
      Enum.reduce(worker_list, acc, fn {id, model, status, node}, acc ->
        Map.update(acc, model, [{id, model, status, node}], fn models ->
          [{id, status, node}] ++ models
        end)
      end)
    end)
  end
end
