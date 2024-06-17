#!/bin/sh

if [ $# -ne 1 ]; then
  echo "Usage: $0 <vus_value>"
  exit 1
fi

VUS=$1
export VUS

echo "Executing k6 with ${VUS} vus"
k6 run ./k6/script.js
