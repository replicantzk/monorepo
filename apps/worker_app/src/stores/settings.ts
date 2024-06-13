import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import { immer } from "zustand/middleware/immer";
import { generateWorkerSalt } from "worker_sdk";
import { Settings, DEFAULT_SETTINGS } from "../utils/settings";

type SettingsStore = {
  workerAPIKey: string;
  workerSalt: string;
  urlServer: string;
  urlLLM: string;
  getSettings: () => Settings;
  setSettings: (newSettings: Partial<Settings>) => void;
};

export const useSettingsStore = create(
  persist(
    immer<SettingsStore>((set, get) => ({
      workerAPIKey: DEFAULT_SETTINGS.workerAPIKey,
      workerSalt: generateWorkerSalt(),
      urlServer: DEFAULT_SETTINGS.urlServer,
      urlLLM: DEFAULT_SETTINGS.urlLLM,
      getSettings: () => ({
        workerAPIKey: get().workerAPIKey,
        workerSalt: get().workerSalt,
        urlServer: get().urlServer,
        urlLLM: get().urlLLM
      }),
      setSettings: (newSettings: Partial<Settings>) =>
        set((state) => ({
          ...state,
          ...newSettings,
        })),
    })),
    {
      name: "settings",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
