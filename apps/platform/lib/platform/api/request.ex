defmodule Platform.API.Request do
  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.Accounts.User
  alias Platform.API.Transaction

  @derive {Jason.Encoder, only: [:uuid, :params]}
  @primary_key {:uuid, :string, autogenerate: false}
  schema "requests" do
    field :status, :string
    field :type, Ecto.Enum, values: [:completion]
    field :params, :map
    field :response, :string
    field :tokens, :integer
    field :reward, :integer
    field :time_start, :utc_datetime
    field :time_end, :utc_datetime

    belongs_to :requester, User
    has_one :worker, User
    has_one :transaction, Transaction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [
      :uuid,
      :status,
      :params,
      :response,
      :tokens,
      :reward,
      :time_start,
      :time_end,
      :requester_id
    ])
    |> validate_required([:params, :requester_id, :time_start])
  end
end
