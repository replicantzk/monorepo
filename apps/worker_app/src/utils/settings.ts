export type Settings = {
  workerAPIKey: string;
  workerSalt: string;
  urlServer: string;
  urlLLM: string;
};

export const DEFAULT_SETTINGS: Settings = {
  workerAPIKey: "",
  workerSalt: "",
  urlServer: "wss://platform.replicantzk.com",
  urlLLM: "http://localhost:11434"
};
