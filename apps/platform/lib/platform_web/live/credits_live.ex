defmodule PlatformWeb.CreditsLive do
  use PlatformWeb, :live_view
  alias Platform.Accounts
  alias Platform.API
  alias Platform.API.Transaction

  @transactions_limit 20
  @error_clear 10_000

  def min_balance() do
    Application.fetch_env!(:platform, :credits_min_balance)
  end

  def min_transfer() do
    Application.fetch_env!(:platform, :credits_min_transfer)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <h1 class="text-2xl font-semibold mb-4">Credits</h1>
      <h2 class="text-xl font-semibold mb-2">Balance</h2>
      <p>Required minimum credits: <%= min_balance() %></p>
      <p>Your balance is: <%= @balance %></p>
      <%= if @error != nil and is_atom(@error) do %>
        <p class="text-red-500"><%= format_error(@error) %></p>
      <% end %>
      <h2 class="text-xl font-semibold mb-2">Transfer</h2>
      <p>Required minimum transfer: <%= min_transfer() %></p>
      <form phx-submit="transfer" class="flex flex-row gap-2">
        <input type="email" name="to" placeholder="To" class="input input-bordered w-full max-w-xs" />
        <input
          type="number"
          name="amount"
          placeholder="Amount"
          class="input input-bordered w-full max-w-xs"
        />
        <.button type="submit">Transfer</.button>
      </form>
      <h2 class="text-xl font-semibold mb-2">Transactions</h2>
      <p class="mb-2">Showing last <%= @transactions_limit %> transactions</p>
      <table class="table-auto w-full text-center">
        <thead>
          <tr class="bg-gray-100">
            <th class="px-4 py-2">Timestamp</th>
            <th class="px-4 py-2">Amount</th>
          </tr>
        </thead>
        <tbody>
          <%= for transaction <- @transactions do %>
            <tr>
              <td class="border px-4 py-2">
                <%= NaiveDateTime.to_string(transaction.inserted_at) %>
              </td>
              <td class={"bg-opacity-30 border px-4 py-2 " <>
                if transaction.from == @current_user.id,
                  do: "bg-orange-400",
                  else: "bg-green-400"
              }>
                <%= if transaction.from == @current_user.id,
                  do: -transaction.amount,
                  else: transaction.amount %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    socket = assign_current_user(socket, session)
    current_user = socket.assigns.current_user

    if connected?(socket) do
      topic = "transactions:#{current_user.id}"
      Phoenix.PubSub.subscribe(Platform.PubSub, topic)
    end

    balance = API.get_credits_balance(current_user.id)
    transactions = API.get_transactions(current_user.id, limit: @transactions_limit)

    {:ok,
     socket
     |> assign(balance: balance)
     |> assign(error: nil)
     |> assign(transactions: transactions)
     |> assign(transactions_limit: @transactions_limit)}
  end

  defp format_error(:user_not_found), do: "User not found"
  defp format_error(:negative_amount), do: "Amount cannot be negative"
  defp format_error(:insufficient_funds), do: "Insufficient funds"

  defp format_error(:lt_minimum_transfer),
    do: "Amount is less than minimum transfer of #{min_transfer()}"

  @impl true
  def handle_event("transfer", %{"amount" => amount, "to" => to}, socket) do
    user_from = socket.assigns.current_user
    user_to = Accounts.get_user_by_email(to)
    {amount, _string} = Integer.parse(amount)

    socket =
      cond do
        user_to == nil ->
          assign_error(socket, :user_not_found)

        amount < 0 ->
          assign_error(socket, :negative_amount)

        amount < min_transfer() ->
          assign_error(socket, :lt_minimum_transfer)

        socket.assigns.balance < amount ->
          assign_error(socket, :insufficient_funds)

        true ->
          case API.transfer_credits(amount, user_to.id, user_from.id) do
            {:ok, transaction} ->
              new_transactions =
                Enum.take([transaction | socket.assigns.transactions], @transactions_limit)

              socket
              |> assign(error: nil)
              |> assign(transactions: new_transactions)
              |> assign(balance: socket.assigns.balance - amount)

            {:error, reason} ->
              assign(socket,
                error: reason
              )
          end
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:transaction, %Transaction{from: from_id, to: to_id} = transaction}, socket) do
    current_user = socket.assigns.current_user

    new_transactions =
      Enum.take([transaction] ++ socket.assigns.transactions, @transactions_limit)

    new_balance =
      cond do
        current_user.id == from_id ->
          socket.assigns.balance - transaction.amount

        current_user.id == to_id ->
          socket.assigns.balance + transaction.amount

        true ->
          socket.assigns.balance
      end

    {:noreply,
     socket
     |> assign(transactions: new_transactions)
     |> assign(balance: new_balance)}
  end

  @impl true
  def handle_info(:clear_error, socket) do
    {:noreply, assign(socket, error: nil)}
  end

  defp assign_error(socket, error) do
    Process.send_after(self(), :clear_error, @error_clear)
    assign(socket, error: error)
  end

  defp assign_current_user(socket, session) do
    case session do
      %{"user_token" => user_token} ->
        assign_new(socket, :current_user, fn ->
          Accounts.get_user_by_session_token(user_token)
        end)

      %{} ->
        assign_new(socket, :current_user, fn -> nil end)
    end
  end
end
