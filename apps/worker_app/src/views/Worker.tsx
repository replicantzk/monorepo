import { useState, useEffect } from "react";
import { workerStatus, startWorker } from "worker_sdk";
import useModelsFetch from "../hooks/useModelsFetch";
import { useModelStore } from "../stores/models";
import { useSettingsStore } from "../stores/settings";
import { useWorkerStore } from "../stores/worker";

export default function Worker() {
  const modelsConnected = useModelStore((state) => state.connected);

  const getSettings = useSettingsStore((state) => state.getSettings);
  const urlLLM = useSettingsStore((state) => state.urlLLM);
  const workerAPIKey = useSettingsStore((state) => state.workerAPIKey);

  const running = useWorkerStore((state) => state.running);
  const abortController = useWorkerStore((state) => state.abortController);
  const modelSelected = useWorkerStore((state) => state.modelSelected);
  const logs = useWorkerStore((state) => state.logs);
  const setRunning = useWorkerStore((state) => state.setRunning);
  const setModelRunning = useWorkerStore((state) => state.setModelRunning);
  const setAbortController = useWorkerStore(
    (state) => state.setAbortController
  );
  const addLog = useWorkerStore((state) => state.addLog);
  const clearLogs = useWorkerStore((state) => state.clearLogs);

  const [errorMessage, setErrorMessage] = useState("");
  const [showLogs, setShowLogs] = useState(true);

  const handleModelsFetch = useModelsFetch();

  useEffect(() => {
    calculateReady();
  }, [modelsConnected, urlLLM, workerAPIKey, modelSelected, running]);

  const messageFn = (message: string, status?: workerStatus) => {
    switch (status) {
      case "running":
        setRunning(true);
        setModelRunning(modelSelected);
        break;
      case "stopped":
        setRunning(false);
        setModelRunning(undefined);
        break;
      default:
        console.log(`MESSAGE: ${message} with unknown status: ${status}`);
        break;
    }

    addLog(message);
  };

  const handleStart = async () => {
    const settings = getSettings();
    const opts = {
      ...settings,
      modelName: modelSelected,
    };

    if (modelSelected === undefined) {
      setErrorMessage("Please select a model.");
      return;
    }

    setModelRunning(modelSelected);
    setRunning(true);
    await startWorker({
      messageFn,
      modelName: modelSelected,
      APIKey: opts.workerAPIKey,
      salt: opts.workerSalt,
      urlServer: opts.urlServer,
      urlLLM: opts.urlLLM,
      abortSignal: abortController.signal
    });
  };

  const handleStop = () => {
    setRunning(false);
    if (abortController && !abortController.signal.aborted) {
      abortController.abort();
    }
    setAbortController(new AbortController());
    setModelRunning(undefined);
    setRunning(false);
  };
  const toggleLogs = () => {
    setShowLogs(!showLogs);
  };

  const calculateReady = () => {
    try {
      if (!modelsConnected) {
        throw new Error("Please check your connection to the LLM server.");
      } else if (urlLLM === "") {
        throw new Error("Please set the LLM server URL in settings.");
      } else if (workerAPIKey === "") {
        throw new Error("Please set the worker API key in settings.");
      } else if (modelSelected === undefined && !running) {
        throw new Error("Please select a model to serve.");
      }
      setErrorMessage("");
    } catch (e: any) {
      setErrorMessage(e.message);
    }
  };

  return (
    <div className="flex flex-col flex-grow space-y-4">
      <h1 className="text-2xl font-semibold">Worker</h1>
      <div className="flex flex-row space-x-2">
        <button
          onClick={handleModelsFetch}
          className="btn btn-primary"
          disabled={modelsConnected}
        >
          Refresh
        </button>
        {running ? (
          <button onClick={handleStop} className="btn btn-primary">
            Stop
          </button>
        ) : (
          <button
            onClick={handleStart}
            className="btn btn-primary"
            disabled={errorMessage !== ""}
          >
            Start
          </button>
        )}
      </div>
      {errorMessage !== "" && <span>{errorMessage}</span>}
      {modelSelected !== undefined && <p>Model selected: {modelSelected}</p>}
      <h1 className="text-xl">Logs</h1>
      <div className="flex flex-row space-x-2">
        <button onClick={toggleLogs} className="btn btn-primary">
          {showLogs ? "Hide" : "Show"}
        </button>
        {showLogs && (
          <button onClick={clearLogs} className="btn btn-primary">
            Clear
          </button>
        )}
      </div>
      {showLogs && logs.length > 0 && (
        <div className="flex-grow overflow-x-hidden overflow-y-auto max-h-[300px] bg-base-200 border-2 border-base-300">
          <div className="w-full">
            <pre className="whitespace-pre-wrap break-words text-sm">
              {logs.map((log, index) => (
                <span key={index} className="inline-block w-full">
                  {log}
                </span>
              ))}
            </pre>
          </div>
        </div>
      )}
    </div>
  );
}
