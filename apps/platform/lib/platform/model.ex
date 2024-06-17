defmodule Platform.Model do
  defstruct [:name, :size, :context]

  def supported_models do
    [
      %{
        name: "llama3:8b-instruct-q4_K_M",
        size: 4.9,
        context: 8_192
      },
      %{
        name: "phind-codellama:34b-v2-q4_K_M",
        size: 20,
        context: 16_384
      }
    ]
  end

  def supported_models_keys do
    Enum.map(supported_models(), fn model -> model.name end)
  end

  def count_tokens(text) when is_binary(text) do
    avg_tokens_per_word = Application.fetch_env!(:platform, :avg_tokens_per_word)

    text
    |> String.split(~r{(\\n|[^\w'])+}, trim: true)
    |> Enum.count()
    |> Kernel.*(avg_tokens_per_word)
    |> Kernel.ceil()
  end

  def calculate_reward(key, num_tokens) when is_integer(num_tokens) do
    size_gb_per_credit = Application.fetch_env!(:platform, :size_gb_per_credit)

    model =
      Enum.find(supported_models(), fn model ->
        model.name == key
      end)

    if model do
      ceil(num_tokens * (model.size / size_gb_per_credit))
    else
      0
    end
  end
end
