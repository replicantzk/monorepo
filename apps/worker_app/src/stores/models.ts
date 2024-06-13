import { create } from "zustand";
import { immer } from "zustand/middleware/immer";
import { Model, getSupportedModels } from "../utils/models";

type ModelStore = {
  connected: boolean;
  models: Model[];
  controllers: Record<string, AbortController>;
  setConnected: (connected: boolean) => void;
  setModels: (models: Model[]) => void;
  setDownloadStatus: (name: string, status: string) => void;
  setDownloadPercent: (name: string, percentage: number) => void;
  addController: (name: string, controller: AbortController) => void;
  triggerController: (name: string) => void;
};

export const useModelStore = create(
  immer<ModelStore>((set, _get) => ({
    connected: false,
    models: getSupportedModels(),
    controllers: {},
    setConnected: (connected: boolean) =>
      set((_state) => ({
        connected: connected,
      })),
    setModels: (models: Model[]) =>
      set((_state) => ({
        models: models,
      })),
    setDownloadStatus: (name: string, status: string) =>
      set((state) => ({
        models: state.models.map((model) =>
          model.name === name ? { ...model, downloadStatus: status } : model,
        ),
      })),
    setDownloadPercent: (name: string, percentage: number) =>
      set((state) => ({
        models: state.models.map((model) =>
          model.name === name
            ? {
                ...model,
                downloadPercent: percentage,
              }
            : model,
        ),
      })),
    addController: (name: string, controller: AbortController) =>
      set((state) => ({
        controllers: { ...state.controllers, [name]: controller },
      })),
    triggerController: (name: string) => {
      set((state) => {
        const controller = state.controllers[name];
        if (controller) {
          controller.abort();
          delete state.controllers[name];
        }
      });
    },
  })),
);
