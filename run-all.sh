#!/bin/bash

for OFFLOAD in true false; do
    echo "Running with offload_to_disk=$OFFLOAD"
    bash run-one.sh "$OFFLOAD" 2>&1 | grep -E 'Sent|CountExporter|RSS' | sed 's/^/  /'
done
