# generator

This Go program demonstrates sending OpenTelemetry traces to a configurable OTLP gRPC endpoint using multiple threads:

- **Slow threads**: Each sends a transaction (span) with a configurable duration (default: 10 seconds).
- **Fast threads**: Each sends transactions as quickly as possible.

## Configuration

The OTLP exporter is configured via environment variables:

- `OTEL_EXPORTER_OTLP_ENDPOINT`: The OTLP gRPC endpoint (e.g., `http://localhost:4317`)
- `OTEL_EXPORTER_OTLP_INSECURE`: Set to `true` to disable TLS (useful for local testing)


Thread counts, slow transaction duration, payload size, and client ID are set via command-line flags:

- `-fast`: Number of fast threads (default: 4)
- `-slow`: Number of slow threads (default: 1)
- `-slow-duration`: Duration of each slow transaction (default: 10s, accepts Go duration format, e.g., `30s`, `1m`)
- `-payload-size`: Size of random payload attribute for each span (default: 0, in bytes)
- `-client-id`: Client ID for this generator instance (default: empty)

## Example Usage

```bash
# Send traces to a local collector, using 8 fast threads, 2 slow threads, 30s slow transaction duration, 128-byte payload, and client ID "test-client"
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 OTEL_EXPORTER_OTLP_INSECURE=true go run main.go -fast=8 -slow=2 -slow-duration=30s -payload-size=128 -client-id=test-client
```

## Requirements

- OpenTelemetry Collector or compatible OTLP endpoint

## Notes

- The program will exit after all slow transactions finish.
- Fast threads run until the slow threads complete.
- You can configure additional OpenTelemetry options via environment variables.
