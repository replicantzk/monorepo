#! /bin/sh

if [ -z "$WORKER_MODEL" ]; then
  echo "WORKER_MODEL is not set"
  exit 1
fi

if [ -z "$WORKER_API_KEY" ]; then
  echo "WORKER_API_KEY is not set"
  exit 1
fi

docker run --rm -it \
    --mount type=bind,source="$(pwd)"/.models,target=/app/.models \
    -e WORKER_MODEL="$WORKER_MODEL" \
    -e WORKER_URL_SERVER="$WORKER_URL_SERVER" \
    -e WORKER_API_KEY="$WORKER_API_KEY" \
    ghcr.io/replicantzk/worker:latest
