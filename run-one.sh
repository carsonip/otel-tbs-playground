#!/bin/bash

OFFLOAD_TO_DISK="$1"
PAYLOAD_SIZE="$2"
CONCURRENCY="$3"
# Start the tail collector with offload_to_disk override
./_build/otel-tbs-playground --config tail.yaml --set processors.tail_sampling.offload_to_disk="$OFFLOAD_TO_DISK" &
TAIL_PID=$!

# Give both collectors a moment to start
sleep 2

# Start RSS monitoring for tail collector in background
exec 3< <(
    MAX_RSS=0
    while kill -0 $TAIL_PID 2>/dev/null; do
        RSS=$(ps -o rss= -p $TAIL_PID)
        if [ -n "$RSS" ] && [ "$RSS" -gt "$MAX_RSS" ]; then
            MAX_RSS=$RSS
        fi
        sleep 0.1
    done
    echo "$MAX_RSS"
)

# Run the Go generator with concurrency

GENERATOR_PIDS=()
for ((i=0; i<CONCURRENCY; i++)); do
  (cd generator && OTEL_SERVICE_NAME=generator OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 OTEL_EXPORTER_OTLP_INSECURE=true go run main.go -slow=1 -fast=100 -slow-duration=3s -payload-size="$PAYLOAD_SIZE") &
  GENERATOR_PIDS+=("$!")
done

# Wait for all generator processes to finish
for pid in "${GENERATOR_PIDS[@]}"; do
  wait "$pid"
done

sleep 10

kill $TAIL_PID
read -u 3 MAX_RSS
echo "tail collector RSS high watermark: ${MAX_RSS} KB"
