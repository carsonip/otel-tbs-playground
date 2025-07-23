#!/bin/bash


# Start the sink collector
/home/carson/projects/opentelemetry-collector-contrib/bin/otelcontribcol_linux_amd64 --config sink.yaml &
SINK_PID=$!

# Start the tail collector
/home/carson/projects/opentelemetry-collector-contrib/bin/otelcontribcol_linux_amd64 --config tail.yaml &
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

# Run the Go generator
(cd generator && OTEL_SERVICE_NAME=generator OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 OTEL_EXPORTER_OTLP_INSECURE=true go run main.go -slow=1 -fast=5 -slow-duration=3s)

sleep 10
kill $TAIL_PID
kill $SINK_PID
read -u 3 MAX_RSS
echo "tail collector RSS high watermark: ${MAX_RSS} KB"
