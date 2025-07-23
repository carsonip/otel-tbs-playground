#!/bin/bash

for OFFLOAD in true false; do
  for PAYLOAD_SIZE in 10000 100000; do
    for CONCURRENCY in 1 10; do
      echo "Running with offload_to_disk=$OFFLOAD, payload_size=$PAYLOAD_SIZE, concurrency=$CONCURRENCY"
      bash run-one.sh "$OFFLOAD" "$PAYLOAD_SIZE" "$CONCURRENCY" 2>&1 | grep -E 'Sent|CountExporter|RSS' | sed 's/^/  /'
    done
  done
done
