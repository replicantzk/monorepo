defmodule Platform.API.Token do
  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.Accounts.User

  schema "tokens" do
    field :value, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:value, :user_id])
    |> validate_required([:value, :user_id])
  end
end
