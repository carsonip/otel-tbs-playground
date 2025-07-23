package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"sync"
	"sync/atomic"
	"time"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/sdk/trace"
)

func newOTLPExporter() (trace.SpanExporter, error) {
	return otlptracegrpc.New(context.Background())
}

var (
	numFast      = flag.Int("fast", 4, "number of fast threads")
	numSlow      = flag.Int("slow", 1, "number of slow threads")
	slowDuration = flag.Duration("slow-duration", 10*time.Second, "duration of each slow transaction")
)

func setup() *trace.TracerProvider {
	exporter, err := newOTLPExporter()
	if err != nil {
		fmt.Println("failed to initialize OTLP exporter:", err)
		os.Exit(1)
	}
	tracerProvider := trace.NewTracerProvider(trace.WithSyncer(exporter))
	return tracerProvider
}

func runTransactions(tracerProvider *trace.TracerProvider) {
	tracer := tracerProvider.Tracer("otel-tbs-playground")
	ctx := context.Background()
	var wg sync.WaitGroup
	var doneCh = make(chan struct{})

	slowTxnID := atomic.Int64{}
	// Slow threads: each sends a slow transaction with configurable duration
	for i := 0; i < *numSlow; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			_, span := tracer.Start(ctx, fmt.Sprintf("slow-transaction-%d", slowTxnID.Add(1)))
			span.SetAttributes(
				attribute.String("thread_id", fmt.Sprintf("slow-%d", id)),
			)
			time.Sleep(*slowDuration)
			span.End()
			fmt.Printf("Slow transaction %d finished\n", id)
			close(doneCh)
		}(i)
	}

	fastTxnID := atomic.Int64{}
	// Fast threads: send fast transactions as quickly as possible
	for i := 0; i < *numFast; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for {
				select {
				case <-doneCh:
					return
				default:
				}
				_, span := tracer.Start(ctx, fmt.Sprintf("fast-transaction-%d", fastTxnID.Add(1)))
				span.SetAttributes(
					attribute.String("thread_id", fmt.Sprintf("fast-%d", id)),
				)
				span.End()
				// Optionally, sleep for a tiny amount to avoid overwhelming the exporter
				time.Sleep(10 * time.Millisecond)
			}
		}(i)
	}

	// Wait for all slow transactions to finish, then exit
	wg.Wait()
}

func main() {
	flag.Parse()
	tracerProvider := setup()
	defer tracerProvider.Shutdown(context.Background())
	runTransactions(tracerProvider)
}
