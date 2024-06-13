#! /bin/sh

IMAGE_BASE="ghcr.io/replicantzk/worker"
IMAGE_LATEST="$IMAGE_BASE:latest"
IMAGE_DATE="$IMAGE_BASE:$(date +%Y%m%d)"

docker build \
    --network=host \
    --no-cache \
    -t $IMAGE_LATEST \
    -t "$IMAGE_DATE" \
    .

if [ "$1" = "-p" ]; then
    docker push -a $IMAGE_BASE
fi
