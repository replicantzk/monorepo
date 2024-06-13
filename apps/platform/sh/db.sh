#! /bin/sh

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=platform_dev
DB_CONTAINER=platform_db
DB_IMAGE=ankane/pgvector

if docker ps -a | grep -w $DB_CONTAINER; then docker stop $DB_CONTAINER; fi

docker run --rm --name $DB_CONTAINER \
  -p "$PLATFORM_DB_PORT":5432 \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$POSTGRES_DB \
  -v $(pwd)/.db/data:/var/lib/postgresql/data \
  $DB_IMAGE
