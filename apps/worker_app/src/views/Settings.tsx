import { useState, useEffect } from "react";
import { generateWorkerSalt, generateWorkerID } from "worker_sdk";
import { useSettingsStore } from "../stores/settings";
import { DEFAULT_SETTINGS, Settings as TSettings } from "../utils/settings";

export default function Settings() {
  const getSettings = useSettingsStore((state) => state.getSettings);
  const setSettings = useSettingsStore((state) => state.setSettings);

  const [formData, setFormData] = useState(getSettings());
  const [savedSettings, setSavedSettings] = useState<TSettings>(
    getSettings() as TSettings,
  );
  const [unsavedChanges, setUnsavedChanges] = useState(false);
  const [workerID, setWorkerID] = useState<string>("");

  useEffect(() => {
    handleGenerateWorkerID();
  }, [formData.workerAPIKey, formData.workerSalt]);

  const handleReset = (event: any) => {
    event.preventDefault();

    const newSettings = {
      ...savedSettings,
      urlServer: DEFAULT_SETTINGS.urlServer,
      urlLLM: DEFAULT_SETTINGS.urlLLM
    };

    setSettings(newSettings);
    setFormData(newSettings);
    setUnsavedChanges(true);
  };

  const handleSubmit = (event: any) => {
    event.preventDefault();

    setSettings({ ...formData });

    setSavedSettings({ ...formData });
    setUnsavedChanges(false);
  };

  const handleChange = (event: any) => {
    const { name, type, value, checked } = event.target;
    const inputValue = type === "checkbox" ? checked : value;
    const newFormData = { ...formData, [name]: inputValue };

    setFormData(newFormData);

    const formDataEqualSavedSettings = Object.entries(newFormData).every(
      ([key, value]) => savedSettings[key as keyof TSettings] === value,
    );
    setUnsavedChanges(!formDataEqualSavedSettings);
  };

  const handleGenerateWorkerSalt = async () => {
    const newSalt = generateWorkerSalt();
    setFormData({ ...formData, workerSalt: newSalt });
    setUnsavedChanges(true);
  };

  const handleGenerateWorkerID = async () => {
    const newWorkerID = await generateWorkerID(
      formData.workerAPIKey,
      formData.workerSalt,
    );
    setWorkerID(newWorkerID);
  };

  return (
    <div className="flex flex-col space-y-4">
      <h1 className="text-2xl font-bold">Settings</h1>
      <div className="flex justify-start mb-6 space-x-2 items-center">
        <button onClick={handleSubmit} className="btn btn-primary">
          Save
        </button>
        <button onClick={handleReset} className="btn btn-primary">
          Reset
        </button>
        <button onClick={handleGenerateWorkerSalt} className="btn btn-primary">
          Generate salt
        </button>
        {unsavedChanges && (
          <p className="text-gray-300 text-sm">You have unsaved changes.</p>
        )}
      </div>
      <form className="form-control w-full max-w-lg">
        <div className="flex items-center mb-4">
          <label className="label flex-none w-1/4" htmlFor="workerAPIKey">
            <span>Client ID</span>
          </label>
          <input
            type="text"
            name="workerID"
            value={workerID}
            className="input input-bordered flex-1 w-full"
            disabled
            readOnly={true}
          />
        </div>
        <div className="flex items-center mb-4">
          <label className="label flex-none w-1/4" htmlFor="workerAPIKey">
            <span>API Key</span>
          </label>
          <input
            type="password"
            name="workerAPIKey"
            value={formData.workerAPIKey}
            onChange={handleChange}
            className="input input-bordered flex-1 w-full"
          />
        </div>
        <div className="flex items-center mb-4">
          <label className="label flex-none w-1/4" htmlFor="workerAPIKey">
            <span>Salt</span>
          </label>
          <input
            type="text"
            name="workerSalt"
            value={formData.workerSalt}
            onChange={handleChange}
            className="input input-bordered flex-1 w-full"
          />
        </div>
        <div className="flex items-center mb-4">
          <label className="label flex-none w-1/4" htmlFor="urlServer">
            <span>URL server</span>
          </label>
          <input
            type="text"
            name="urlServer"
            value={formData.urlServer}
            onChange={handleChange}
            className="input input-bordered flex-1 w-full"
          />
        </div>
        <div className="flex items-center mb-4">
          <label className="label flex-none w-1/4" htmlFor="urlLLM">
            <span>URL LLM</span>
          </label>
          <input
            type="text"
            name="urlLLM"
            value={formData.urlLLM}
            onChange={handleChange}
            className="input input-bordered flex-1 w-full"
          />
        </div>
      </form>
    </div>
  );
}
