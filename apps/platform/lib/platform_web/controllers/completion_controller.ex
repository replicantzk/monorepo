defmodule PlatformWeb.CompletionController do
  use PlatformWeb, :controller
  alias Platform.Accounts.User
  alias Platform.AMQPPublisher
  alias Platform.API
  alias Platform.API.ParamsCompletion
  alias Platform.API.Request
  alias Platform.Model
  alias Platform.Repo
  alias Platform.TaskSupervisor

  def check_context_size(request) do
    model = Model.get_by_key(request.params["model"])
    messages = request.params["messages"]

    full_text =
      messages
      |> Enum.map(fn %{"content" => content, "role" => role} -> "#{role}: #{content}\n" end)
      |> Enum.join()

    Model.count_tokens(full_text) <= model.context
  end

  def new(conn, params) do
    request_attrs = %{
      id: Ecto.UUID.generate(),
      type: :completion,
      params: params,
      requester_id: conn.assigns.current_user.id
    }

    with %Ecto.Changeset{valid?: true} <- Request.changeset(%Request{}, request_attrs),
         %Ecto.Changeset{valid?: true} <- ParamsCompletion.changeset(%ParamsCompletion{}, params),
         true <- check_context_size(request_attrs) do
      request_handler(conn, request_attrs)
    else
      %Ecto.Changeset{valid?: false} = changeset ->
        error_changeset(conn, changeset)
    end
  end

  defp request_handler(conn, request_attrs) do
    time_start = :os.timestamp()

    case AMQPPublisher.publish(request_attrs) do
      :ok ->
        Phoenix.PubSub.subscribe(Platform.PubSub, "requests:" <> request_attrs.id)

        receive do
          {:result, worker_user_id, result} ->
            success(conn, worker_user_id, request_attrs, time_start, result)

          {:chunk_start, worker_user_id} ->
            conn
            |> put_resp_header("Cache-Control", "no-cache")
            |> put_resp_header("connection", "keep-alive")
            |> put_resp_header("Content-Type", "text/event-stream; charset=utf-8")
            |> Plug.Conn.send_chunked(200)
            |> sse_loop(worker_user_id, request_attrs, time_start)

          {:error, worker_user_id, reason} ->
            error(conn, worker_user_id, request_attrs, time_start, reason)
        after
          Application.fetch_env!(:platform, :request_timeout) ->
            error(conn, nil, request_attrs, time_start, "timeout")
        end

      {:error, reason} ->
        error(conn, nil, request_attrs, time_start, reason)
    end
  end

  defp sse_loop(conn, worker_user_id, request_attrs, time_start, text_acc \\ "") do
    receive do
      {:chunk, chunk} ->
        text = extract_text_chunk(chunk)
        text_acc = text_acc <> text

        case Plug.Conn.chunk(conn, chunk) do
          {:ok, conn} ->
            sse_loop(conn, worker_user_id, request_attrs, time_start, text_acc)

          {:error, reason} ->
            error_chunk(conn, worker_user_id, request_attrs, time_start, reason)
        end

      :chunk_end ->
        success_chunk(conn, worker_user_id, request_attrs, time_start, text_acc)

      {:error, reason} ->
        error_chunk(conn, worker_user_id, request_attrs, time_start, reason)

      _unknown ->
        sse_loop(conn, worker_user_id, request_attrs, time_start, text_acc)
    after
      Application.fetch_env!(:platform, :request_timeout_chunk) ->
        error_chunk(conn, worker_user_id, request_attrs, time_start, "timeout")
    end
  end

  defp success(conn, worker_user_id, request_attrs, time_start, result) do
    text = extract_text_result(result)
    handle_success(worker_user_id, request_attrs, time_start, result["model"], text)

    conn
    |> put_status(200)
    |> json(result)
  end

  defp success_chunk(conn, worker_user_id, request_attrs, time_start, text_acc) do
    handle_success(
      worker_user_id,
      request_attrs,
      time_start,
      request_attrs.params["model"],
      text_acc
    )

    conn
  end

  defp error(conn, worker_user_id, request_attrs, time_start, reason) do
    handle_error(worker_user_id, request_attrs, time_start, reason)

    conn
    |> put_status(500)
    |> json(%{error: reason})
  end

  def error_chunk(conn, worker_user_id, request_attrs, time_start, reason) do
    handle_error(worker_user_id, request_attrs, time_start, reason)

    Plug.Conn.chunk(conn, "error: #{reason}\n")
  end

  defp error_changeset(conn, changeset) do
    conn
    |> put_status(500)
    |> put_view(json: PlatformWeb.ChangesetJSON)
    |> render("error.json", changeset: changeset)
  end

  defp handle_success(worker_user_id, request_attrs, time_start, model, text) do
    Task.Supervisor.start_child(TaskSupervisor, fn ->
      time_end = :os.timestamp()
      latency = diff_timestamp_ms(time_start, time_end)
      num_tokens = Model.count_tokens(text)
      reward = Model.calculate_reward(model, num_tokens)

      new_request_attrs =
        request_attrs
        |> Map.put(:status, "200")
        |> Map.put(:latency, latency)
        |> Map.put(:response, text)
        |> Map.put(:tokens, num_tokens)
        |> Map.put(:reward, reward)
        |> Map.put(:worker_id, worker_user_id)

      worker_user = Repo.get(User, worker_user_id)
      requester_user = Repo.get(User, request_attrs.requester_id)

      requester_topic = "transactions:#{requester_user.id}"
      worker_topic = "transactions:#{worker_user.id}"

      tx_id =
        case API.transfer_credits(reward, worker_user, requester_user) do
          {:ok, transaction} when requester_user.id != worker_user.id ->
            Phoenix.PubSub.broadcast(
              Platform.PubSub,
              requester_topic,
              {:transaction, transaction}
            )

            Phoenix.PubSub.broadcast(Platform.PubSub, worker_topic, {:transaction, transaction})
            transaction.id

          _ ->
            nil
        end

      new_request_attrs = Map.put(new_request_attrs, :transaction_id, tx_id)
      API.create_request(new_request_attrs)
    end)
  end

  defp handle_error(_worker_user_id, request_attrs, time_start, reason) do
    Task.Supervisor.start_child(TaskSupervisor, fn ->
      time_end = :os.timestamp()
      latency = diff_timestamp_ms(time_start, time_end)

      new_request_attrs =
        request_attrs
        |> Map.put(:status, "500")
        |> Map.put(:latency, latency)
        |> Map.put(:response, reason)

      API.create_request(new_request_attrs)
    end)
  end

  # %{
  #   "choices" => [
  #     %{
  #       "finish_reason" => "stop",
  #       "index" => 0,
  #       "message" => %{
  #         "content" => "Operation Barbarossa was a military campaign launched by Emperor Adolf Hitler in 1945 to conquer the Western Front of World War II. The campaign involved several major battles, including the Battle of Stalingrad and the Battle of Balaclava.\n\nOperation Barbarossa was a significant turning point in World War II, marking the end of the war and the beginning of a new era of global conflict.\n",
  #         "role" => "assistant"
  #       }
  #     }
  #   ],
  #   "created" => 1715115371,
  #   "id" => "chatcmpl-454",
  #   "model" => "qwen:0.5b-chat-v1.5-q4_K_M",
  #   "object" => "chat.completion",
  #   "system_fingerprint" => "fp_ollama",
  #   "usage" => %{
  #     "completion_tokens" => 84,
  #     "prompt_tokens" => 0,
  #     "total_tokens" => 84
  #   }
  # }

  defp extract_text_result(result) do
    try do
      result
      |> Map.get("choices")
      |> List.first()
      |> get_in(["message", "content"])
    rescue
      _ -> ""
    end
  end

  # "data: {\"id\":\"chatcmpl-668\",\"object\":\"chat.completion.chunk\",\"created\":1715114855,\"model\":\"qwen:0.5b-chat-v1.5-q4_K_M\",\"system_fingerprint\":\"fp_ollama\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\" of\"},\"finish_reason\":null}]}\n\n"

  def extract_text_chunk(chunk) do
    chunk
    |> String.trim()
    |> String.split("data: ")
    |> Enum.reduce("", fn str, acc ->
      if str == "[DONE]" do
        acc
      else
        str_formatted =
          str
          |> String.trim()
          |> (fn s -> if String.starts_with?(s, "{\""), do: s, else: "{\"#{s}" end).()
          |> (fn s -> if String.ends_with?(s, "}"), do: s, else: "#{s}}" end).()

        case Jason.decode(str_formatted) do
          {:ok, decoded} ->
            text =
              try do
                decoded
                |> Map.get("choices", [])
                |> List.first()
                |> get_in(["delta", "content"])
              rescue
                _ -> ""
              end

            acc <> text

          {:error, _} ->
            acc
        end
      end
    end)
  end

  def diff_timestamp_ms(time1, time2) do
    :timer.now_diff(time2, time1)
    |> div(1000)
    |> round()
  end
end
