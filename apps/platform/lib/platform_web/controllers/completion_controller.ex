defmodule PlatformWeb.CompletionController do
  use PlatformWeb, :controller
  alias Platform.AMQPPublisher
  alias Platform.API
  alias Platform.API.ParamsCompletion
  alias Platform.API.Request
  alias Platform.Model

  def new(conn, params) do
    request_attrs =
      %Request{
        requester_id: conn.assigns.current_user.id,
        type: :completion,
        params: params,
        time_start: DateTime.utc_now()
      }
      |> Map.from_struct()

    with %Ecto.Changeset{valid?: true} <- Request.changeset(%Request{}, request_attrs),
         %Ecto.Changeset{valid?: true} <- ParamsCompletion.changeset(%ParamsCompletion{}, params),
         :ok <- AMQPPublisher.publish(request_attrs) do
      handle_request(conn, request_attrs)
    else
      %Ecto.Changeset{valid?: false} = changeset ->
        error_changeset(conn, changeset)

      error ->
        error(conn, request_attrs, error)
    end
  end

  defp handle_request(conn, request_attrs) do
    Phoenix.PubSub.subscribe(Platform.PubSub, "requests:" <> request_attrs.id)

    receive do
      {:result, worker_id, response} ->
        request_attrs = %{request_attrs | worker_id: worker_id}

        case get_in_result(response) do
          {:ok, response_text} ->
            success(conn, %{request_attrs | response: response_text})

          {:error, reason} ->
            error(conn,request_attrs, reason)
        end

      {:chunk_start, worker_id} ->
        conn
        |> put_resp_header("connection", "keep-alive")
        |> put_resp_header("Content-Type", "text/event-stream; charset=utf-8")
        |> put_resp_header("Cache-Control", "no-cache")
        |> Plug.Conn.send_chunked(200)
        |> sse(%{request_attrs | worker_id: worker_id})

      {:error, worker_id, reason} ->
        error(conn, %{request_attrs | worker_id: worker_id}, reason)
    after
      Application.fetch_env!(:platform, :request_timeout) ->
        error(conn, request_attrs, :timeout)
    end
  end

  defp sse(conn, request_attrs, text_acc \\ "") do
    receive do
      {:chunk, chunk} ->
        with {:ok, text} <- extract_chunk_text(chunk),
             {:ok, conn} <- Plug.Conn.chunk(conn, chunk) do
          sse(conn, request_attrs, text_acc <> text)
        else
          {:error, reason} ->
            error_chunk(conn, %{request_attrs | response: text_acc}, reason)
        end

      :chunk_end ->
        success_chunk(conn, %{request_attrs | response: text_acc})

      {:error, reason} ->
        error_chunk(conn, request_attrs, reason)

      _unknown ->
        sse(conn, request_attrs, text_acc)
    after
      Application.fetch_env!(:platform, :request_timeout_chunk) ->
        error_chunk(conn, request_attrs, :timeout_chunk)
    end
  end

  defp error_changeset(conn, changeset) do
    conn
    |> put_status(500)
    |> put_view(json: PlatformWeb.ChangesetJSON)
    |> render("error.json", changeset: changeset)
  end

  defp error(conn, request_attrs, reason) do
    handle_error(request_attrs, reason)

    conn
    |> put_status(500)
    |> json(%{error: reason})
  end

  defp error_chunk(conn, request_attrs, reason) do
    handle_error(request_attrs, reason)

    Plug.Conn.chunk(conn, format_error(reason))
  end

  defp success(conn, request_attrs) do
    handle_success(request_attrs)

    conn
    |> put_status(200)
    |> json(request_attrs.response)
  end

  defp success_chunk(conn, request_attrs) do
    handle_success(request_attrs)

    conn
  end

  defp handle_error(request_attrs, reason) do
    Task.start(fn ->
      request_attrs
      |> Map.put(:status, "500")
      |> Map.put(:time_end, DateTime.utc_now())
      |> Map.put(:response, format_error(reason))
      |> API.create_request()
    end)
  end

  defp handle_success(request_attrs) do
    Task.start(fn ->
      n_tokens = Model.count_tokens(request_attrs.response)
      reward = Model.calculate_reward(request_attrs.model, n_tokens)

      request_attrs =
        request_attrs
        |> Map.put(:status, "200")
        |> Map.put(:tokens, n_tokens)
        |> Map.put(:reward, reward)
        |> Map.put(:time_end, DateTime.utc_now())
        |> API.create_request()

      requester_id = request_attrs.requester_id
      worker_id = request_attrs.worker_id

      if requester_id != worker_id do
        requester_topic = "transactions:#{requester_id}"
        worker_topic = "transactions:#{worker_id}"

        {:ok, transaction} = API.transfer_credits(reward, worker_id, requester_id)

        Phoenix.PubSub.broadcast(
          Platform.PubSub,
          requester_topic,
          {:transaction, transaction}
        )

        Phoenix.PubSub.broadcast(
          Platform.PubSub,
          worker_topic,
          {:transaction, transaction}
        )

        API.update_request(request_attrs, %{transaction_id: transaction.id})
      end
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

  defp get_in_result(result) do
    case get_in(result, ["choices", 0, "message", "content"]) do
      nil -> {:error, :parse}
      result -> {:ok, result}
    end
  end

  # "data: {\"id\":\"chatcmpl-668\",\"object\":\"chat.completion.chunk\",\"created\":1715114855,\"model\":\"qwen:0.5b-chat-v1.5-q4_K_M\",\"system_fingerprint\":\"fp_ollama\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\" of\"},\"finish_reason\":null}]}\n\n"

  defp get_in_delta(result) do
    case get_in(result, ["choices", 0, "delta", "content"]) do
      nil -> {:error, :parse}
      result -> {:ok, result}
    end
  end

  defp extract_chunk_text(chunk) do
    chunk
    |> String.trim()
    |> String.split("data: ")
    |> Enum.reduce("", fn str, acc ->
      case str do
        "[DONE]" ->
          acc

        result ->
          encoded =
            result
            |> String.trim()
            |> format_bracket_start()
            |> format_bracket_end()

          with {:ok, decoded} <- Jason.decode(encoded),
               {:ok, text} <- get_in_delta(decoded) do
            acc <> text
          else
            _ ->
              acc
          end
      end
    end)
  end

  defp format_bracket_start(text),
    do: if(String.starts_with?(text, "{\""), do: text, else: "{\"#{text}}")

  defp format_bracket_end(text), do: if(String.ends_with?(text, "}"), do: text, else: "#{text}}")
  defp format_error_prefix(), do: "ERROR: "

  defp format_error(reason) when is_atom(reason),
    do: format_error_prefix() <> Atom.to_string(reason)

  defp format_error(reason) when is_binary(reason), do: format_error_prefix() <> reason
  defp format_error(reason), do: format_error_prefix() <> inspect(reason)
end
