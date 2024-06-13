defmodule Platform.APIFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Platform.API` context.
  """

  @doc """
  Generate a token.
  """
  def token_fixture(attrs \\ %{}) do
    {:ok, token} =
      attrs
      |> Enum.into(%{
        value: "some value"
      })
      |> Platform.API.create_token()

    token
  end

  @doc """
  Generate a webhook.
  """
  def webhook_fixture(attrs \\ %{}) do
    {:ok, webhook} =
      attrs
      |> Enum.into(%{
        input: %{},
        status: "some status",
        url: "some url"
      })
      |> Platform.API.create_webhook()

    webhook
  end

  @doc """
  Generate a request.
  """
  def request_fixture(attrs \\ %{}) do
    {:ok, request} =
      attrs
      |> Enum.into(%{
        id: "some id",
        params: %{},
        response: "some response",
        status: "some status"
      })
      |> Platform.API.create_request()

    request
  end
end
