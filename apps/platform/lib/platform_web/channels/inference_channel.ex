defmodule PlatformWeb.InferenceChannel do
  use PlatformWeb, :channel
  require Logger
  alias Phoenix.PubSub
  alias Platform.API
  alias Platform.ConnectionLimiter
  alias Platform.WorkerBalancer

  @impl true
  def join(
        "inference:" <> worker_id,
        %{"model" => model, "key" => _key, "salt" => _salt} = payload,
        socket
      ) do
    Logger.put_process_level(self(), :error)

    ip = RemoteIp.from(socket.assigns.x_headers)

    with {:ok, user} <- authorized?(ip, worker_id, payload),
         true <- WorkerBalancer.join(worker_id, model) do
      {:ok,
       socket
       |> assign(worker_id: worker_id)
       |> assign(user: user)}
    else
      {:error, reason} when is_atom(reason) ->
        {:error, %{reason: Atom.to_string(reason)}}

      _ ->
        {:error, %{reason: "server error"}}
    end
  end

  def join(_topic, _payload) do
    {:error, %{reason: "invalid request"}}
  end

  defp authorized?(
         ip,
         worker_id,
         %{"model" => _model, "key" => key, "salt" => salt}
       ) do
    with true <- ConnectionLimiter.check({ip, key}),
         {:ok, user} <- API.get_user_by_token(key),
         true <- worker_id == generate_worker_id(key, salt) do
      {:ok, user}
    else
      _ ->
        {:error, :unauthorized}
    end
  end

  def leave(worker_id) do
    WorkerBalancer.leave(worker_id)
    {:shutdown, :left}
  end

  @impl true
  def handle_in(
        "result",
        %{"id" => request_id, "result" => result},
        socket
      ) do
    worker_user_id = socket.assigns.user.id
    broadcast_response(request_id, {:result, worker_user_id, result})
    worker_id = get_worker_id(socket)
    WorkerBalancer.free(worker_id)

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "result_chunk_start",
        %{"id" => request_id},
        socket
      ) do
    worker_user_id = socket.assigns.user.id
    broadcast_response(request_id, {:chunk_start, worker_user_id})

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "result_chunk",
        %{"id" => request_id, "chunk" => chunk},
        socket
      ) do
    broadcast_response(request_id, {:chunk, chunk})

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "result_chunk_end",
        %{"id" => request_id},
        socket
      ) do
    broadcast_response(request_id, :chunk_end)
    worker_id = get_worker_id(socket)
    WorkerBalancer.free(worker_id)

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "result_error",
        %{"id" => request_id, "error" => reason},
        socket
      ) do
    broadcast_response(request_id, {:error, reason})
    worker_id = get_worker_id(socket)
    WorkerBalancer.free(worker_id)

    {:noreply, socket}
  end

  @impl true
  def handle_out(
        "disconnect",
        _payload,
        socket
      ) do
    WorkerBalancer.leave(worker_id)

    {:stop, :shutdown, socket}
  end

  @impl true
  def terminate(reason, socket) do
    worker_id = get_worker_id(socket)
    Logger.info("Terminating channel for worker: #{worker_id} due to #{inspect(reason)}")
    WorkerBalancer.leave(worker_id)

    :ok
  end

  defp get_worker_id(socket) do
    "inference:" <> worker_id = socket.topic
    worker_id
  end

  defp broadcast_response(request_id, message) do
    PubSub.broadcast(
      Platform.PubSub,
      "requests:" <> request_id,
      message
    )
  end

  def generate_worker_id(key, salt) do
    :crypto.hash(:sha256, key <> salt)
    |> Base.encode16()
    |> String.downcase()
  end
end
