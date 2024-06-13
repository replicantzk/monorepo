#! /bin/sh

if [ $# -gt 2 ] || ([ $# -eq 1 ] && [ "$1" != "-f" ]); then
    echo "Usage: $0 [-f]"
    exit 1
fi

if [ "$1" = "-f" ]; then
    (cd ./apps/worker_sdk && npm run build)
    docker compose down --remove-orphans
    docker compose build --no-cache
fi

docker compose up
