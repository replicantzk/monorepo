defmodule Platform.ConnectionLimiter do
  def cache_name(), do: :connection_limiter

  def check(key) do
    reset_ms = Application.fetch_env!(:platform, :conn_limit_reset)
    limit_per_second = Application.fetch_env!(:platform, :conn_limit_ps)

    time_now = NaiveDateTime.utc_now()

    {_result, {count, time_last}} =
      Cachex.fetch(:connection_limiter, key, fn _key ->
        {:commit, {0, time_now}}
      end)

    time_diff_ms = NaiveDateTime.diff(time_now, time_last, :millisecond)

    cond do
      time_diff_ms > reset_ms ->
        Cachex.put(:connection_limiter, key, {0, time_now})
        true

      count < limit_per_second ->
        Cachex.put(:connection_limiter, key, {count + 1, time_now})
        true

      true ->
        false
    end
  end
end
