defmodule Platform.API do
  @moduledoc """
  The API context.
  """
  import Ecto.Query, warn: false
  alias Platform.Accounts
  alias Platform.API.Request
  alias Platform.API.Token
  alias Platform.API.Transaction
  alias Platform.Repo

  @system_email "platform@replicantzk.com"

  @doc """
  Returns the list of tokens.

  ## Examples

      iex> list_tokens()
      [%Token{}, ...]

  """
  def list_tokens do
    Repo.all(Token)
  end

  @doc """
  Gets a single token.

  Raises `Ecto.NoResultsError` if the Token does not exist.

  ## Examples

      iex> get_token!(123)
      %Token{}

      iex> get_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_token!(id), do: Repo.get!(Token, id)

  def get_token_by_user(user) do
    from(t in Token,
      where: t.user_id == ^user.id
    )
    |> Repo.one()
  end

  def get_user_by_token(value) do
    query =
      from(t in Token,
        join: u in assoc(t, :user),
        where: t.value == ^value,
        select: u
      )

    case Repo.one(query) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Creates a token.

  ## Examples

      iex> create_token(%{field: value})
      {:ok, %Token{}}

      iex> create_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_token(attrs \\ %{}) do
    %Token{}
    |> Token.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a token.

  ## Examples

      iex> update_token(token, %{field: new_value})
      {:ok, %Token{}}

      iex> update_token(token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_token(%Token{} = token, attrs) do
    token
    |> Token.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a token.

  ## Examples

      iex> delete_token(token)
      {:ok, %Token{}}

      iex> delete_token(token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_token(%Token{} = token) do
    Repo.delete(token)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking token changes.

  ## Examples

      iex> change_token(token)
      %Ecto.Changeset{data: %Token{}}

  """
  def change_token(%Token{} = token, attrs \\ %{}) do
    Token.changeset(token, attrs)
  end

  @doc """
  Returns the list of requests.

  ## Examples

      iex> list_requests()
      [%Request{}, ...]

  """
  def list_requests do
    Repo.all(Request)
  end

  @doc """
  Gets a single request.

  Raises `Ecto.NoResultsError` if the Request does not exist.

  ## Examples

      iex> get_request!(123)
      %Request{}

      iex> get_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_request!(id), do: Repo.get!(Request, id)

  @doc """
  Creates a request.

  ## Examples

      iex> create_request(%{field: value})
      {:ok, %Request{}}

      iex> create_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_request(attrs \\ %{}) do
    %Request{}
    |> Request.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a request.

  ## Examples

      iex> update_request(request, %{field: new_value})
      {:ok, %Request{}}

      iex> update_request(request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_request(%Request{} = request, attrs) do
    request
    |> Request.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a request.

  ## Examples

      iex> delete_request(request)
      {:ok, %Request{}}

      iex> delete_request(request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_request(%Request{} = request) do
    Repo.delete(request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking request changes.

  ## Examples

      iex> change_request(request)
      %Ecto.Changeset{data: %Request{}}

  """
  def change_request(%Request{} = request, attrs \\ %{}) do
    Request.changeset(request, attrs)
  end

  def list_transactions() do
    Repo.all(Transaction)
  end

  def get_transaction!(id), do: Repo.get!(Transaction, id)

  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  def get_credits_balance(user_id) do
    debits =
      Repo.one(
        from t in Transaction,
          where: t.to == ^user_id,
          select: sum(t.amount)
      ) || 0

    credits =
      Repo.one(
        from t in Transaction,
          where: t.from == ^user_id,
          select: sum(t.amount)
      ) || 0

    debits - credits
  end

  def get_transactions(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit)

    query =
      from t in Transaction,
        where: t.from == ^user_id or t.to == ^user_id,
        order_by: [desc: t.inserted_at]

    query = if limit, do: limit(query, ^limit), else: query

    Repo.all(query)
  end
  
  def get_system_credit_account() do
    case Accounts.get_user_by_email(@system_email) do
      nil ->
        account_attrs = %{
          email: @system_email,
          password: Ecto.UUID.generate()
        }

        Accounts.register_user(account_attrs)

      user ->
        {:ok, user}
    end
  end

  def transfer_credits(amount, user_to_id, user_from_id) do
    transaction_attrs = %{
      from: user_from_id,
      to: user_to_id,
      amount: amount
    }

    if get_credits_balance(user_from_id) < amount do
      {:error, :insufficient_funds}
    else
      create_transaction(transaction_attrs)
    end
  end

  def transfer_credits(amount, user_to_id) do
    {:ok, user_from} = get_system_credit_account()

    transaction_attrs = %{
      from: user_from.id,
      to: user_to_id,
      amount: amount
    }

    create_transaction(transaction_attrs)
  end
end
