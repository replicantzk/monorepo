defmodule PlatformWeb.InferenceChannel do
  use PlatformWeb, :channel
  require Logger
  alias Phoenix.PubSub
  alias Platform.API
  alias Platform.Balancer
  alias Platform.ConnectionLimiter

  intercept ["disconnect"]

  @impl true
  def join(
        "inference:" <> client_id,
        %{"model" => model, "key" => key, "salt" => salt},
        socket
      ) do
    Logger.put_process_level(self(), :error)

    ip = RemoteIp.from(socket.assigns.x_headers)

    with {:ok, worker} <- authorized?(ip, client_id, key, salt),
         true <- Balancer.join(client_id, model) do
      {:ok,
       socket
       |> assign(client_id: client_id)
       |> assign(worker: worker)}
    else
      {:error, reason} ->
        {:error, %{reason: inspect(reason)}}
    end
  end

  def join(_topic, _payload, _socket) do
    {:error, %{reason: "invalid request"}}
  end

  defp authorized?(ip, client_id, key, salt) do
    with :ok <- ConnectionLimiter.check({ip, key}),
         :ok <- validate_client_id(client_id, key, salt),
         {:ok, worker} <- API.get_user_by_token(key) do
      {:ok, worker}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def handle_in(
        "result",
        %{"id" => request_id, "result" => result},
        socket
      ) do
    client_id = socket.assigns.client_id
    worker_id = socket.assigns.worker.id
    Balancer.free(socket.assigns.client_id)
    broadcast_response(request_id, {:result, result, worker_id, client_id})

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "chunk_start",
        %{"id" => request_id},
        socket
      ) do
    client_id = socket.assigns.client_id
    worker_id = socket.assigns.worker.id
    broadcast_response(request_id, {:chunk_start, worker_id, client_id})

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "chunk",
        %{"id" => request_id, "chunk" => chunk},
        socket
      ) do
    broadcast_response(request_id, {:chunk, chunk})

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "chunk_end",
        %{"id" => request_id},
        socket
      ) do
    client_id = socket.assigns.client_id
    Balancer.free(client_id)
    broadcast_response(request_id, :chunk_end)

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "error",
        %{"id" => request_id, "error" => reason},
        socket
      ) do
    client_id = socket.assigns.client_id
    worker_id = socket.assigns.worker.id
    Balancer.leave(client_id)
    broadcast_response(request_id, {:error, reason, worker_id, client_id})

    {:stop, :shutdown, socket}
  end

  @impl true
  def handle_in(
        "chunk_error",
        %{"id" => request_id, "error" => reason},
        socket
      ) do
    client_id = socket.assigns.client_id
    Balancer.leave(client_id)
    broadcast_response(request_id, {:chunk_error, reason})

    {:stop, :shutdown, socket}
  end

  @impl true
  def handle_out(
        "disconnect",
        _payload,
        socket
      ) do
    Balancer.leave(socket.assigns.client_id)

    {:stop, :shutdown, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    Balancer.leave(socket.assigns.client_id)

    :ok
  end

  def validate_client_id(client_id, key, salt) do
    generated_client_id =
      :crypto.hash(:sha256, key <> salt)
      |> Base.encode16()
      |> String.downcase()

    if generated_client_id == client_id do
      :ok
    else
      {:error, :invalid_client_id}
    end
  end

  defp broadcast_response(request_id, message) do
    PubSub.broadcast(
      Platform.PubSub,
      "requests:" <> request_id,
      message
    )
  end
end
