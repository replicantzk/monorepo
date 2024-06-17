defmodule Platform.API.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.API.Request

  schema "transactions" do
    field :from, :integer
    field :to, :integer
    field :amount, :integer

    belongs_to :request, Request

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:from, :to, :amount, :request_id])
    |> validate_required([:from, :to, :amount])
  end
end
