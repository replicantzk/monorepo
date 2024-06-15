#! /bin/bash

trap 'kill $(jobs -p)' SIGINT

(sh/db_test.sh) &
(sh/mq.sh) &

sleep 5

mix test

wait
