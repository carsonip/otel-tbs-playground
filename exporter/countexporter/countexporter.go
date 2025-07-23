package countexporter

import (
	"context"
	"fmt"
	"sync/atomic"

	"go.opentelemetry.io/collector/pdata/ptrace"
)

type CountExporter struct {
	requestCount atomic.Int64
	spanCount    atomic.Int64
}

func New() *CountExporter {
	return &CountExporter{}
}

func (e *CountExporter) ConsumeTraces(_ context.Context, td ptrace.Traces) error {
	e.requestCount.Add(1)
	e.spanCount.Add(int64(td.SpanCount()))
	return nil
}

func (e *CountExporter) Shutdown(_ context.Context) error {
	fmt.Printf("CountExporter: %d requests, %d spans received\n", e.requestCount.Load(), e.spanCount.Load())
	return nil
}
