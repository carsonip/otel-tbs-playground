#!/bin/bash


# Start the OpenTelemetry Collector and show output, kill after 10 seconds
/home/carson/projects/opentelemetry-collector-contrib/bin/otelcontribcol_linux_amd64 --config otel-collector-tail-sampling.yaml &
COLLECTOR_PID=$!
# Give the collector a moment to start
sleep 2
# Run the Go generator
(cd generator && OTEL_SERVICE_NAME=generator OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 OTEL_EXPORTER_OTLP_INSECURE=true go run main.go -slow=1 -fast=5 -slow-duration=3s)

sleep 10
kill $COLLECTOR_PID
