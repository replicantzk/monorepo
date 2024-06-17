defmodule Platform.API.Request do
  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.Accounts.User
  alias Platform.API.Transaction

  @derive {Jason.Encoder, only: [:id, :params]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "requests" do
    field :status, :string
    field :type, Ecto.Enum, values: [:completion]
    field :params, :map
    field :response, :string
    field :tokens, :integer
    field :reward, :integer
    field :time_start, :utc_datetime
    field :time_end, :utc_datetime

    belongs_to :requester, User, foreign_key: :requester_id
    belongs_to :worker, User, foreign_key: :worker_id
    has_one :transaction, Transaction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [
      :id,
      :status,
      :params,
      :response,
      :tokens,
      :reward,
      :time_start,
      :time_end,
      :requester_id
    ])
    |> validate_required([:params, :time_start, :requester_id])
  end
end
