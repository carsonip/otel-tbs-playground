#!/bin/bash

# Start the OpenTelemetry Collector and show output, monitor RSS
/home/carson/projects/opentelemetry-collector-contrib/bin/otelcontribcol_linux_amd64 --config otel-collector-tail-sampling.yaml &
COLLECTOR_PID=$!

# Give the collector a moment to start
sleep 2

# Start RSS monitoring in background
exec 3< <(
    MAX_RSS=0
    while kill -0 $COLLECTOR_PID 2>/dev/null; do
        RSS=$(ps -o rss= -p $COLLECTOR_PID)
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
kill $COLLECTOR_PID
read -u 3 MAX_RSS
echo "otelcontribcol RSS high watermark: ${MAX_RSS} KB"
