#! /bin/bash

doppler secrets download \
    --no-file \
    --format env \
    --project platform \
    --config dev \
    > .env
