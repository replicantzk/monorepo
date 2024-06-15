defmodule Platform.APITest do
  use Platform.DataCase

  alias Platform.API

  describe "tokens" do
    alias Platform.API.Token

    import Platform.AccountsFixtures
    import Platform.APIFixtures

    @invalid_attrs %{value: nil}

    test "list_tokens/0 returns all tokens" do
      Platform.Repo.delete_all(Token)
      user = user_fixture()
      token = token_fixture(%{user_id: user.id})
      assert API.list_tokens() == [token]
    end

    test "get_token!/1 returns the token with given id" do
      user = user_fixture()
      token = token_fixture(%{user_id: user.id})
      assert API.get_token!(token.id) == token
    end

    test "create_token/1 with valid data creates a token" do
      user = user_fixture()

      valid_attrs = %{
        user_id: user.id,
        value: "some value"
      }

      assert {:ok, %Token{} = token} = API.create_token(valid_attrs)
      assert token.value == "some value"
    end

    test "create_token/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = API.create_token(@invalid_attrs)
    end

    test "update_token/2 with valid data updates the token" do
      user = user_fixture()
      token = token_fixture(%{user_id: user.id})
      update_attrs = %{value: "some updated value"}

      assert {:ok, %Token{} = token} = API.update_token(token, update_attrs)
      assert token.value == "some updated value"
    end

    test "update_token/2 with invalid data returns error changeset" do
      user = user_fixture()
      token = token_fixture(%{user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = API.update_token(token, @invalid_attrs)
      assert token == API.get_token!(token.id)
    end

    test "delete_token/1 deletes the token" do
      user = user_fixture()
      token = token_fixture(%{user_id: user.id})
      assert {:ok, %Token{}} = API.delete_token(token)
      assert_raise Ecto.NoResultsError, fn -> API.get_token!(token.id) end
    end

    test "change_token/1 returns a token changeset" do
      user = user_fixture()
      token = token_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = API.change_token(token)
    end
  end

  describe "requests" do
    alias Platform.API.Request

    import Platform.AccountsFixtures
    import Platform.APIFixtures

    @invalid_attrs %{id: nil, status: nil, response: nil, params: nil}

    test "list_requests/0 returns all requests" do
      user = user_fixture()
      request = request_fixture(%{requester_id: user.id})
      assert API.list_requests() == [request]
    end

    test "get_request!/1 returns the request with given id" do
      user = user_fixture()
      request = request_fixture(%{requester_id: user.id})
      assert API.get_request!(request.uuid) == request
    end

    test "create_request/1 with valid data creates a request" do
      user = user_fixture()

      valid_attrs = %{
        status: "some status",
        response: "some response",
        params: %{},
        requester_id: user.id,
        time_start: DateTime.utc_now(),
      }

      assert {:ok, %Request{} = request} = API.create_request(valid_attrs)
      assert request.status == "some status"
      assert request.response == "some response"
      assert request.params == %{}
    end

    test "create_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = API.create_request(@invalid_attrs)
    end

    test "update_request/2 with valid data updates the request" do
      user = user_fixture()
      request = request_fixture(%{requester_id: user.id})

      update_attrs = %{
        status: "some updated status",
        response: "some updated response",
        params: %{}
      }

      assert {:ok, %Request{} = request} = API.update_request(request, update_attrs)
      assert request.status == "some updated status"
      assert request.response == "some updated response"
      assert request.params == %{}
    end

    test "update_request/2 with invalid data returns error changeset" do
      user = user_fixture()
      request = request_fixture(%{requester_id: user.id})
      assert {:error, %Ecto.Changeset{}} = API.update_request(request, @invalid_attrs)
      assert request == API.get_request!(request.uuid)
    end

    test "delete_request/1 deletes the request" do
      user = user_fixture()
      request = request_fixture(%{requester_id: user.id})
      assert {:ok, %Request{}} = API.delete_request(request)
      assert_raise Ecto.NoResultsError, fn -> API.get_request!(request.uuid) end
    end

    test "change_request/1 returns a request changeset" do
      user = user_fixture()
      request = request_fixture(%{requester_id: user.id})
      assert %Ecto.Changeset{} = API.change_request(request)
    end
  end
end
