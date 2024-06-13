#! /bin/sh

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=replicant_platform_test
DB_CONTAINER=db_replicant_platform_test
DB_IMAGE=ankane/pgvector

if docker ps -a | grep -w $DB_CONTAINER; then docker kill $DB_CONTAINER; fi

docker run --rm --name $DB_CONTAINER \
  -p "$PLATFORM_DB_PORT":5432 \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$POSTGRES_DB \
  -v $(pwd)/.db/data_test:/var/lib/postgresql/data \
  $DB_IMAGE

AMQP_CONTAINER=platform_mq_test
AMQP_IMAGE=rabbitmq:3.12-management

if docker ps -a | grep -w $AMQP_CONTAINER; then docker kill $AMQP_CONTAINER; fi

docker run -it --rm --name $AMQP_CONTAINER \
  -p "$PLATFORM_AMQP_PORT":5672 \
  -p "$PLATFORM_AMQP_MANAGEMENT_PORT":15672 \
  $AMQP_IMAGE
