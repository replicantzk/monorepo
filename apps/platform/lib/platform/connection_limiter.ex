defmodule Platform.ConnectionLimiter do
  def check(key) do
    reset_seconds = Application.fetch_env!(:platform, :connection_limit_reset)
    limit_per_second = Application.fetch_env!(:platform, :connection_limit_ps)
    time_now = NaiveDateTime.utc_now()

    {_result, {count, time_last}} =
      Cachex.fetch(:connection_limiter, key, fn _key ->
        {:commit, {0, time_now}}
      end)

    time_diff = NaiveDateTime.diff(time_now, time_last, :second)

    cond do
      time_diff > reset_seconds ->
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
