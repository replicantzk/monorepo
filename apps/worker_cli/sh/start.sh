#! /bin/sh

STARTUP_DELAY=${WORKER_STARTUP_DELAY:-3}
MODELS_PATH=${WORKER_MODELS_PATH:-./.models}

if [ -z "${WORKER_MODEL}" ]; then
  echo "WORKER_MODEL is not set"
  exit 1
fi

mkdir -p "${MODELS_PATH}"
export OLLAMA_MODELS="${MODELS_PATH}"

ollama serve &

sleep "${STARTUP_DELAY}"

ollama pull "${WORKER_MODEL}"

./replicant-worker
