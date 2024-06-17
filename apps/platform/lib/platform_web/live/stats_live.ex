defmodule PlatformWeb.StatsLive do
  use PlatformWeb, :live_view
  import Ecto.Query
  alias Contex.BarChart
  alias Contex.Dataset
  alias Contex.Plot
  alias Platform.API.Request
  alias Platform.API.Transaction
  alias Platform.Repo

  @recent_days 7
  @plot_size %{height: 300, width: 600}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col space-y-4">
      <h1 class="text-2xl font-semibold">Stats</h1>

      <div class="flex flex-col">
        <%= for {title, plot} <- @plots do %>
          <div class="flex flex-col space-y-2 text-center">
            <h3 class="text-xl"><%= title %></h3>
            <%= plot %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    plots = [
      {"Requests last #{@recent_days} days",
       @recent_days
       |> requests_recent()
       |> render_bar_chart("Day", "Requests")},
      {"Rewards last #{@recent_days} days",
       @recent_days
       |> rewards_recent()
       |> render_bar_chart("User", "Rewards")},
      {"Rewards all time", render_bar_chart(rewards_all_time(), "User", "Rewards")}
    ]

    {:ok, assign(socket, :plots, plots)}
  end

  def requests_recent(days) do
    from(
      r in Request,
      where: r.inserted_at >= ago(^days, "day"),
      group_by: [fragment("date_trunc('day', ?)", r.inserted_at)],
      select: %{day: fragment("date_trunc('day', ?)", r.inserted_at), count: count(r.id)}
    )
    |> Repo.all()
    |> Enum.map(fn %{day: day, count: count} ->
      {Date.to_iso8601(day), count}
    end)
    |> Enum.sort(fn {a, _}, {b, _} -> a < b end)
  end

  def rewards_recent(days) do
    from(
      r in Transaction,
      where: r.inserted_at >= ago(^days, "day"),
      group_by: r.to,
      select: %{user: r.to, sum: sum(r.amount)},
      order_by: [desc: fragment("sum")]
    )
    |> Repo.all()
    |> Enum.map(fn %{user: user, sum: sum} ->
      {user, sum}
    end)
  end

  def rewards_all_time() do
    from(
      r in Transaction,
      group_by: r.to,
      select: %{user: r.to, sum: sum(r.amount)},
      order_by: [desc: fragment("sum")]
    )
    |> Repo.all()
    |> Enum.map(fn %{user: user, sum: sum} ->
      {user, sum}
    end)
  end

  defp render_bar_chart(data, x_label, y_label) do
    if data != [] do
      data
      |> Dataset.new()
      |> Plot.new(BarChart, @plot_size.width, @plot_size.height, colour_palette: ["4ADE80"])
      |> Plot.axis_labels(x_label, y_label)
      |> Plot.to_svg()
    else
      "No data"
    end
  end
end
