import { useEffect } from "react";
import { useSettingsStore } from "../stores/settings";
import { useModelStore } from "../stores/models";
import { getModels, mergeModels, getSupportedModels } from "../utils/models";

export default function useModelsFetch() {
  const setConnected = useModelStore((state) => state.setConnected);
  const storeModels = useModelStore((state) => state.models);
  const setModels = useModelStore((state) => state.setModels);
  const urlLLM = useSettingsStore((state) => state.urlLLM);

   const handleModelsFetch= async () => {
    try {
      const localModels = await getModels(urlLLM);
      const models = mergeModels(storeModels, localModels);
      setModels(models)
      setConnected(true);
    } catch (e: any) {
      console.log("Error fetching models: ", e.message);
      setModels(getSupportedModels());
      setConnected(false);
    }
  };

  useEffect(() => {
    handleModelsFetch();
  }, []);

  return handleModelsFetch;
}
