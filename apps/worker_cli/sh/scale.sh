#!/bin/bash

REGIONS="yyz,ord"

ACTION=$1
COUNT=${2:-0}
MAX_PER_REGION=$((COUNT / 2 + COUNT % 2))

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <up|down> [<count>]"
    exit 1
fi

if [ "$ACTION" = "up" ]; then
    echo "Scaling up to $COUNT with max $MAX_PER_REGION per region..."
    fly scale count "$COUNT" --region $REGIONS --max-per-region $MAX_PER_REGION
elif [ "$ACTION" = "down" ]; then
    echo "Scaling down to $COUNT..."
    fly scale count --yes "$COUNT"
else
    echo "Invalid action. Use 'up' or 'down'."
fi
