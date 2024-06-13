import { useState } from "react";
import useModelsFetch from "../hooks/useModelsFetch";
import { useModelStore } from "../stores/models";
import { useSettingsStore } from "../stores/settings";
import { useWorkerStore } from "../stores/worker";
import { Model, downloadModel, deleteModel } from "../utils/models";

export default function Models() {
  const connected = useModelStore((state) => state.connected);
  const models = useModelStore((state) => state.models);
  const addController = useModelStore((state) => state.addController);
  const triggerController = useModelStore((state) => state.triggerController);
  const setDownloadStatus = useModelStore((state) => state.setDownloadStatus);
  const setDownloadPercent = useModelStore((state) => state.setDownloadPercent);
  const setConnected = useModelStore((state) => state.setConnected);

  const urlLLM = useSettingsStore((state) => state.urlLLM);
  const modelRunning = useWorkerStore((state) => state.modelRunning);
  const modelSelected = useWorkerStore((state) => state.modelSelected);
  const setModelSelected = useWorkerStore((state) => state.setModelSelected);

  const [errorMessage, setErrorMessage] = useState("");

  const handleModelsFetch = useModelsFetch();
  const handleReset = async () => {
    setModelSelected(undefined);
  };

  const handleDownload = async (name: string) => {
    try {
      setDownloadStatus(name, "downloading");
      const controller = new AbortController();
      addController(name, controller);
      await downloadModel(urlLLM, name, controller, setDownloadPercent);
      setDownloadStatus(name, "downloaded");
      setErrorMessage("");
    } catch (e: any) {
      if (e.name !== "AbortError") {
        console.error(e);
        setErrorMessage(e.message);
      }

      setDownloadStatus(name, "not downloaded");
      setDownloadPercent(name, 0);
    }
  };

  const handleDownloadCancel = (name: string) => {
    try {
      triggerController(name);
      setDownloadStatus(name, "not downloaded");
      setDownloadPercent(name, 0);
      setErrorMessage("");
    } catch (e: any) {
      console.error(e);
      setErrorMessage(e.message);
    }
  };

  const handleDelete = async (name: string) => {
    try {
      setDownloadStatus(name, "deleting");
      await deleteModel(urlLLM, name);
      setDownloadStatus(name, "not downloaded");
      setDownloadPercent(name, 0);
      setErrorMessage("");
      setConnected(true);
    } catch (e: any) {
      console.error(e);
      setDownloadStatus(name, "downloaded");
      setErrorMessage(e.message);
      setConnected(false);
    }
  };

  const handleServe = (name: string) => {
    setModelSelected(name);
  };

  const renderDownload = (model: Model) => {
    switch (model.downloadStatus) {
      case "not downloaded":
        return (
          <button
            onClick={() => handleDownload(model.name)}
            className="btn btn-primary"
          >
            Download
          </button>
        );
      case "downloaded":
        return (
          <button
            onClick={() => handleDelete(model.name)}
            className="btn btn-primary"
            disabled={
              model.name === modelSelected || model.name === modelRunning
            }
          >
            Delete
          </button>
        );
      case "downloading":
        return (
          <div className="flex flex-row space-x-2 items-center">
            <progress
              className="progress w-32"
              value={model.downloadPercent}
              max="100"
            ></progress>
            <button
              onClick={() => handleDownloadCancel(model.name)}
              className="btn btn-primary"
            >
              Cancel
            </button>
          </div>
        );
      case "deleting":
        return <p>Deleting...</p>;
    }
  };

  const renderServe = (model: Model) => {
    return (
      <div>
        {model.downloadStatus === "downloaded" &&
          (model.name !== modelSelected ? (
            <button
              onClick={() => handleServe(model.name)}
              className="btn btn-primary"
            >
              Serve
            </button>
          ) : (
            <p>✔️</p>
          ))}
      </div>
    );
  };

  return (
    <div className="flex flex-col space-y-4">
      <h1 className="text-2xl font-bold">Models</h1>
      <div className="flex flex-row space-x-2">
        <button onClick={handleModelsFetch} className="btn btn-primary" disabled={urlLLM === ""}>
          Refresh
        </button>
        <button onClick={handleReset} className="btn btn-primary">
          Reset
        </button>
      </div>
      {urlLLM !== "" ? (
        !connected && (
          <p>Please check your connection to the LLM server.</p>
        )
      ) : (
        <p className="text-gray-300 text-sm">
          Please set `URL LLM` in the Settings page to manage models.
        </p>
      )}
      {errorMessage !== "" && (
        <div>
          <p className="text-sm text-gray-400">{errorMessage}</p>
        </div>
      )}
      {connected && urlLLM !== "" && (
        <div>
          <table className="table max-w-fit text-center">
            <thead>
              <tr>
                <th>Name</th>
                <th>Size (GB)</th>
                <th>Download</th>
                <th>Serve</th>
              </tr>
            </thead>
            <tbody>
              {models.map((model) => (
                <tr key={model.name} className="hover">
                  <td>{model.name}</td>
                  <td>{model.size}</td>
                  <td>{renderDownload(model)}</td>
                  <td>{renderServe(model)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
