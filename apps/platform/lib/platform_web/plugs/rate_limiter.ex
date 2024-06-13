defmodule PlatformWeb.Plugs.RateLimiter do
  import Plug.Conn
  alias Cachex

  def init(opts), do: opts

  def call(conn, _opts) do
    if Application.fetch_env!(:platform, :rate_limit_enable) do
      current_user = conn.assigns[:current_user]
      limit_per_second = current_user.rate_limit
      time_now = NaiveDateTime.utc_now()

      case Cachex.fetch(:rate_limiter, current_user.id) do
        {:ok, {count, time_last}} ->
          seconds_elapsed = NaiveDateTime.diff(time_now, time_last, :second)
          reset_period_seconds = Application.fetch_env!(:platform, :rate_limiter_reset)
          counter_reset = seconds_elapsed > reset_period_seconds

          cond do
            counter_reset ->
              Cachex.put(:rate_limiter, current_user.id, {0, time_now})
              conn

            count < limit_per_second * reset_period_seconds ->
              Cachex.put(:rate_limiter, current_user.id, {count + 1, time_now})
              conn

            true ->
              limit_exceeded(conn)
          end

        _ ->
          Cachex.put(:rate_limiter, current_user.id, {0, time_now})
          conn
      end
    else
      conn
    end
  end

  defp limit_exceeded(conn) do
    conn
    |> send_resp(429, "Rate limit exceeded")
    |> halt()
  end
end
