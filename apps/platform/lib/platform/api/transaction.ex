defmodule Platform.API.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :from, :integer
    field :to, :integer
    field :amount, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:from, :to, :amount])
    |> validate_required([:from, :to, :amount])
  end
end
