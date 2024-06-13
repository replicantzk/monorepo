#! /bin/sh

AMQP_CONTAINER=platform_mq
AMQP_IMAGE=rabbitmq:3.12-management

if docker ps -a | grep -w $AMQP_CONTAINER; then docker kill $AMQP_CONTAINER; fi

docker run --rm --name $AMQP_CONTAINER \
  -p "$PLATFORM_AMQP_PORT":5672 \
  -p "$PLATFORM_AMQP_MANAGEMENT_PORT":15672 \
  -v $(pwd)/.mq/data:/var/lib/rabbitmq \
  $AMQP_IMAGE
