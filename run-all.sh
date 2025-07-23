#!/bin/bash

for OFFLOAD in true false; do
  for PAYLOAD_SIZE in 10000 100000; do
    echo "Running with offload_to_disk=$OFFLOAD, payload_size=$PAYLOAD_SIZE"
    bash run-one.sh "$OFFLOAD" "$PAYLOAD_SIZE" 2>&1 | grep -E 'Sent|CountExporter|RSS' | sed 's/^/  /'
  done
done
