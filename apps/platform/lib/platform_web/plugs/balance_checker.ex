defmodule PlatformWeb.Plugs.BalanceChecker do
  import Plug.Conn
  alias Platform.API

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = conn.assigns[:current_user]

    case Cachex.fetch(:balances, current_user.id, fn _user_id ->
           {:commit, API.get_credits_balance(current_user)}
         end) do
      {result, balance} when result in [:ok, :commit] and balance >= 0 ->
        conn

      _ ->
        insufficient_balance(conn)
    end
  end

  defp insufficient_balance(conn) do
    conn
    |> send_resp(402, "Insufficient balance")
    |> halt()
  end
end
