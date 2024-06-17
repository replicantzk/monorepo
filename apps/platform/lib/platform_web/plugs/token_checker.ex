defmodule PlatformWeb.Plugs.TokenChecker do
  import Plug.Conn
  alias Platform.API

  def cache_name(), do: :token_checker

  def init(opts), do: opts

  def call(conn, _opts) do
    header = get_req_header(conn, "authorization")
    validate_header(conn, header)
  end

  defp validate_header(conn, ["Bearer " <> token]) do
    case Cachex.fetch(cache_name(), token, &fallback/1) do
      {result, user} when result in [:ok, :commit] ->
        assign(conn, :current_user, user)

      {:error, :not_found} ->
        not_validated(conn)
    end
  end

  defp validate_header(conn, _header) do
    not_validated(conn)
  end

  defp fallback(token) do
    case API.get_user_by_token(token) do
      {:ok, user} ->
        {:commit, user}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp not_validated(conn) do
    conn
    |> send_resp(401, "Invalid authorization header")
    |> halt()
  end
end
