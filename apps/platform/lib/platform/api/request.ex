defmodule Platform.API.Request do
  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.Accounts.User
  alias Platform.API.Transaction

  @derive {Jason.Encoder, only: [:id, :params]}

  @primary_key {:id, :string, autogenerate: false}
  schema "requests" do
    field :status, :string
    field :type, Ecto.Enum, values: [:completion]
    field :params, :map
    field :response, :string
    field :latency, :integer
    field :tokens, :integer
    field :reward, :integer

    belongs_to :requester, User
    has_one :worker, User
    has_one :transaction, Transaction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [
      :id,
      :requester_id,
      :status,
      :params,
      :response,
      :latency,
      :tokens,
      :reward
    ])
    |> cast_assoc(:worker)
    |> cast_assoc(:transaction)
    |> validate_required([:id, :params, :requester_id])
  end
end
