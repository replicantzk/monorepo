defmodule Platform.APIFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Platform.API` context.
  """

  @doc """
  Generate a token.
  """
  def token_fixture(%{user_id: user_id} = attrs) do
    {:ok, token} =
      attrs
      |> Enum.into(%{
        user_id: user_id,
        value: Ecto.UUID.generate()
      })
      |> Platform.API.create_token()

    token
  end

  @doc """
  Generate a request.
  """
  def request_fixture(attrs \\ %{}) do
    {:ok, request} =
      attrs
      |> Enum.into(%{
        params: %{},
        response: "some response",
        status: "some status",
        time_start: DateTime.utc_now()
      })
      |> Platform.API.create_request()

    request
  end
end
