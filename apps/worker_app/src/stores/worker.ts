import { create } from "zustand";
import { immer } from "zustand/middleware/immer";

const DEFAULT_MAX_LOGS = 30;

type WorkerStore = {
  running: boolean;
  abortController: AbortController;
  modelRunning?: string;
  modelSelected?: string;
  logs: string[];
  maxLogs: number;
  setRunning: (running: boolean) => void;
  setAbortController: (abortController: AbortController) => void;
  setModelRunning: (model: string | undefined) => void;
  setModelSelected: (model: string | undefined) => void;
  addLog: (log: string) => void;
  clearLogs: () => void;
};

export const useWorkerStore = create(
  immer<WorkerStore>((set, _get) => ({
    running: false,
    abortController: new AbortController(),
    modelRunning: undefined,
    modelSelected: undefined,
    logs: [],
    maxLogs: DEFAULT_MAX_LOGS,
    setRunning: (running: boolean) =>
      set((_state) => ({
        running: running,
      })),
    setAbortController: (abortController: AbortController) =>
      set((_state) => ({
        abortController: abortController,
      })),
    setModelRunning: (model: string | undefined) =>
      set((_state) => ({
        modelRunning: model,
      })),
    setModelSelected: (model: string | undefined) =>
      set((_state) => ({
        modelSelected: model,
      })),
    addLog: (log: string) =>
      set((state) => ({
        logs: [log].concat(
          state.logs.length >= DEFAULT_MAX_LOGS
            ? state.logs.slice(0, -1)
            : state.logs,
        ),
      })),
    clearLogs: () =>
      set((_state) => ({
        logs: [],
        logSize: 0,
      })),
  })),
);
