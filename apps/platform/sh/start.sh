#! /bin/bash

trap 'kill $(jobs -p)' SIGINT

(sh/db.sh) &
(sh/mq.sh) &

sleep 5

mix ecto.migrate

(iex -S mix phx.server) &

wait
