#! /bin/sh

git submodule update --init --recursive

mise install

mix do local.rebar --force, local.hex --force
mix escript.install hex livebook --force

(cd ./apps/appchain && npm install)
(cd ./apps/onchain && poetry install)
(cd ./apps/platform && mix deps.get)
(cd ./apps/site && npm install)
(cd ./apps/worker_sdk && npm install && npm run build)
(cd ./apps/worker_app && npm install)
(cd ./apps/worker_cli && bun install)
