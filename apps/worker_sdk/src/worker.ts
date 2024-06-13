import { Socket } from "phoenix";
import {
  CHANNEL_NAME,
  TOPIC_CHUNK,
  TOPIC_CHUNK_END,
  TOPIC_CHUNK_START,
  TOPIC_ERROR,
  TOPIC_REQUEST,
  TOPIC_RESULT,
} from "./consts";
import { generateWorkerID } from "./crypto";
import { requestSchema } from "./schema";
import { InMemoryStorage } from "./ws";

export type workerStatus = "running" | "stopped";

export interface startWorkerArgs {
  messageFn: (message: string, status?: workerStatus) => void;
  modelName: string;
  APIKey: string;
  salt: string;
  urlServer: string;
  urlLLM: string;
  abortSignal?: AbortController["signal"];
}

export async function startWorker({
  messageFn,
  modelName,
  APIKey,
  salt,
  urlServer,
  urlLLM,
  abortSignal
}: startWorkerArgs): Promise<void> {
  var socket: Socket | undefined = undefined;

  if (abortSignal !== undefined) {
    abortSignal.addEventListener("abort", () => {
      if (socket !== undefined) {
        socket.disconnect();
        messageFn(`Worker aborted`, "stopped");
      }
    });
  }

  try {
    const workerID = generateWorkerID(APIKey, salt);
    const channelStr = `${CHANNEL_NAME}:${workerID}`;
    const joinArgs = {
      model: modelName,
      key: APIKey,
      salt: salt,
    };

    messageFn(`Starting worker`);
    messageFn(`Worker ID - ${workerID}`);
    messageFn(`Channel - ${channelStr}`);
    messageFn(`Model - ${modelName}`);

    const tags = await fetch(`${urlLLM}/api/tags`, {
      method: "GET",
    });

    if (tags.status && tags.status !== 200) {
      throw new Error("Failed to fetch tags from LLM");
    }

    const tagsJson = await tags.json();

    if (
      tagsJson.models === undefined ||
      tagsJson.models.find((model) => model.name === modelName) === undefined
    ) {
      throw new Error(`Model ${modelName} not downloaded`);
    }

    socket = new Socket(urlServer, {
      transport: WebSocket,
      sessionStorage: InMemoryStorage,
    });

    const channel = socket.channel(channelStr, joinArgs);

    socket.connect();

    socket.onOpen(() => {
      messageFn(`Connected to the socket`, "running");
    });

    socket.onClose(() => {
      messageFn(`Socket closed`, "stopped");
    });

    socket.onError((_error) => {
      messageFn("Socket error", "stopped");
      socket.disconnect();
    });

    channel
      .join()
      .receive("ok", (_resp) => {
        messageFn(`Socket joined channel ${channelStr}`, "running");
      })
      .receive("error", ({ reason }) => {
        messageFn(
          `Socket failed to join channel ${channelStr} due to ${reason}`,
          "stopped",
        );
        socket.disconnect();
      })
      .receive("timeout", () => {
        messageFn(
          `Socket failed to join channel ${channelStr} due to timeout`,
          "stopped",
        );
        socket.disconnect();
      });

    channel.on(TOPIC_REQUEST, async (message: any) => {
      const request = requestSchema.parse(message);
      const requestId = request.id;

      try {
        messageFn(`Received request: ${requestId}`);
        const params = request.params;
        const paramsJson = JSON.stringify(params);

        const response = await fetch(
          `${urlLLM}/v1/chat/completions
        `,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: paramsJson,
          },
        );

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        if (response.body === null) {
          throw new Error("Response body is null");
        }

        if (request.params.stream) {
          channel.push(TOPIC_CHUNK_START, { id: request.id });
          messageFn(`Streaming response for ${request.id}`);

          const reader = response.body.getReader();
          const decoder = new TextDecoder();

          let done, value;
          while (!done) {
            ({ value, done } = await reader.read());
            if (value !== undefined && !done) {
              let chunkStr = decoder.decode(value);
              channel.push(TOPIC_CHUNK, {
                id: request.id,
                chunk: chunkStr,
              });
            } else if (done) {
              channel.push(TOPIC_CHUNK_END, {
                id: request.id,
              });
              messageFn(`Streaming complete for ${request.id}`);
            }
          }
        } else {
          const result = await response.json();
          channel.push(TOPIC_RESULT, { id: request.id, result: result });
          messageFn(`${JSON.stringify(result)}`);
        }
      } catch (e: any) {
        channel.push(TOPIC_ERROR, { id: request.id, error: e.message });
        messageFn(`${e.message}`, "stopped");
      }
    });
  } catch (e: any) {
    const message = `Worker error: ${e.message}`;
    messageFn(`${message}`, "stopped");
  }
}
