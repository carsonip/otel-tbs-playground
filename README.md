# otel-tbs-playground

## Overview
This project demonstrates OpenTelemetry integration with a tail-based sampling collector. It includes a generator component that sends telemetry data to the tail collector, and scripts for running parameterized tests. The main goal is to compare the performance of the collector with disk offloading disabled and enabled, using the `offload_to_disk` option from a [fork of the tail sampling processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/compare/main...carsonip:opentelemetry-collector-contrib:tailsampling-pebble).

## Generator and Tail Collector
The generator (located in `generator/main.go`) produces telemetry data (traces, metrics, etc.) and sends it to the tail collector. The tail collector refers to a collector instance with the tail sampling processor enabled, as configured in `tail.yaml`.

### Data Flow and Count Exporter Integration
The generator (located in `generator/main.go`) uses OpenTelemetry SDKs to create and export telemetry data (traces, metrics, etc.), which is sent to the tail collector endpoint specified in the configuration files. The tail collector refers to a collector instance with the tail sampling processor enabled, as configured in `tail.yaml`.

Within the collector pipeline, the count exporter (see `exporter/countexporter/`) is configured to report the number of requests and spans received. It tracks and outputs metrics on the total number of requests and spans processed, which is useful for monitoring throughput and verifying test scenarios. After receiving data, the tail collector processes incoming telemetry, applies tail-based sampling, and exports sampled traces to the backend.

## Running Parameterized Tests
The script `run-all.sh` is used to execute parameterized tests across different configurations and scenarios.

### How `run-all.sh` Works
`run-all.sh` iterates over a set of test parameters (such as different collector configs, generator options, etc.). For each parameter set, it launches the generator and collector with the specified settings, collects results, and outputs them for analysis. Tests are run both with and without the `offload_to_disk` option, a new configuration from a fork of the tail sampling processor. The output of each run includes:
- Number of spans sent by the generator
- Number of spans received by the countexporter
- Maximum resident set size (RSS) of the collector process
- Database disk usage (if `offload_to_disk` is enabled)

## Getting Started
1. Clone the repository.
2. Review and update configuration files (`tail.yaml`, `manifest.yaml`) as needed.
3. Build the project:
   ```bash
   make build
   ```
4. Use `run-all.sh` to execute tests:
   ```bash
   ./run-all.sh
   ```
5. Check output and logs for test results.

## Results

See [RESULTS.md](./RESULTS.md)

