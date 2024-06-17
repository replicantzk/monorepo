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
    |> validate_inclusion(:stream, [true, false])
    |> validate_number(:temperature, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_inclusion(:model, Model.supported_models_keys())
    |> validate_messages()
    |> validate_context_size()
  end

  def validate_messages(changeset) do
    messages = get_field(changeset, :messages)

    if Enum.all?(messages, fn message ->
         Map.keys(message) == ["content", "role"] &&
           Enum.all?(Map.values(message), &is_binary/1)
       end),
       do: changeset,
       else: add_error(changeset, :messages, "Invalid messages format")
  end

  def validate_context_size(changeset) do
    messages = get_field(changeset, :messages)
    model_key = get_field(changeset, :model)
    model = Model.get_by_key(model_key)

    n_tokens =
      messages
      |> Enum.reduce("", fn map, acc ->
        acc <> "#{map["role"]}: #{map["content"]}\n"
      end)
      |> Model.count_tokens()

    if n_tokens > model.context,
      do: add_error(changeset, :messages, "Text input is larger than context size"),
      else: changeset
  end
end
