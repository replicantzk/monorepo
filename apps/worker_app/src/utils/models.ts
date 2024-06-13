export type DownloadStatus =
  | "not downloaded"
  | "downloading"
  | "downloaded"
  | "deleting";

export type Model = {
  name: string;
  size: number;
  downloadStatus: DownloadStatus;
  downloadPercent: number;
};

export type ModelStub = {
  name: string;
  size: number;
};

const stubsToModels = (stubs: ModelStub[], otherFields: object): Model[] => {
  return stubs.map((stub: ModelStub) => {
    return {
      ...otherFields,
      name: stub.name,
      size: stub.size,
    } as Model;
  });
};

export const getSupportedModels = () => {
  return stubsToModels(
    [
      { name: "llama3:8b-instruct-q4_K_M", size: 4.9 },
      { name: "phind-codellama:34b-v2-q4_K_M", size: 20 },
    ],
    {
      downloadStatus: "not downloaded",
      downloadPercent: 0,
    }
  );
};

export function mergeModels(
  currentModels: Model[],
  newModels: Model[],
  allowNew: boolean = false,
  sortFn: (a: Model, b: Model) => number = (a, b) =>
    a.name.localeCompare(b.name)
): Model[] {
  let result: Model[] = [...currentModels];
  newModels.forEach((model: Model) => {
    const index = result.findIndex(
      (existingModel: Model) => model.name === existingModel.name
    );
    if (index !== -1) {
      result[index] = model;
    } else if (allowNew) {
      result.push(model);
    }
  });

  return result.sort(sortFn);
}

export async function heartbeatModels(url: string): Promise<boolean> {
  const response = await fetch(url + "/api/tags", {
    method: "GET",
  });

  return response.status === 200;
}

export async function getModels(url: string): Promise<Model[]> {
  const response = await fetch(url + "/api/tags", {
    method: "GET",
  });

  if (response.status !== 200) {
    throw new Error("Response status was not 200, got: " + response.status);
  }

  const data = await response.json();
  const downloadedModels = data.models;

  if (!Array.isArray(downloadedModels)) {
    throw new Error("Expected models to be an array");
  }

  const localModels = stubsToModels(
    downloadedModels.map((model) => {
      return {
        name: model.name,
        size: Math.round((model.size / 10 ** 9) * 10) / 10,
      };
    }),
    {
      downloadStatus: "downloaded",
      downloadPercent: 100,
    }
  );

  return mergeModels(getSupportedModels(), localModels);
}

export async function downloadModel(
  url: string,
  name: string,
  abortController?: AbortController,
  updateFn?: (name: string, percent: number) => void
): Promise<void> {
  const response = await fetch(url + "/api/pull", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ name: name, stream: true }),
    signal: abortController?.signal,
  });

  if (response.status !== 200) {
    throw new Error("Response status was not 200, got: " + response.status);
  }

  if (updateFn !== undefined) {
    if (response.body === null) {
      throw new Error("Response body is null");
    }

    const data = response.body;
    const reader = data?.getReader();
    const decoder = new TextDecoder();

    let textAcc = "";
    let percent = 0;
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      if (value !== undefined) {
        const valueText = decoder.decode(value);

        textAcc += valueText;

        const endsNewLine = textAcc.endsWith("\n");

        if (endsNewLine) {
          for (const line of textAcc.split("\n")) {
            if (line !== "") {
              const valueJSON = JSON.parse(line);

              if (valueJSON.total && valueJSON.completed) {
                const total = parseInt(valueJSON.total);
                const completed = parseInt(valueJSON.completed);
                const newPercent = (completed / total) * 100;

                if (newPercent !== percent) {
                  percent = newPercent;
                  updateFn(name, percent);
                }
              }
            }
          }

          textAcc = "";
        }
      }
    }
  }
}

export async function deleteModel(url: string, name: string): Promise<void> {
  const body = { name: name };

  const response = await fetch(url + "/api/delete", {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (response.status !== 200) {
    throw new Error("Response status was not 200, got: " + response.status);
  }
}
