defmodule Platform.API.ParamsCompletion do
  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.Model

  embedded_schema do
    field :model, :string
    field :messages, {:array, :map}
    field :stream, :boolean, default: false
    field :temperature, :float, default: 0.0
  end

  def changeset(params, attrs) do
    params
    |> cast(attrs, [:model, :messages, :stream, :temperature])
    |> validate_required([:model, :messages])
    |> validate_inclusion(:model, Model.supported_models_keys())
    |> validate_inclusion(:stream, [true, false])
    |> validate_number(:temperature, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
  end
end
