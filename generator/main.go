package main

import (
	"context"
	"flag"
	"fmt"
	"math/rand"
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
	payloadSize  = flag.Int("payload-size", 0, "size of random payload attribute for each span")
)

func setup() *trace.TracerProvider {
	exporter, err := newOTLPExporter()
	if err != nil {
		fmt.Println("failed to initialize OTLP exporter:", err)
		os.Exit(1)
	}
	tracerProvider := trace.NewTracerProvider(trace.WithBatcher(exporter, func(o *trace.BatchSpanProcessorOptions) {
		o.BatchTimeout = 100 * time.Millisecond
		o.MaxExportBatchSize = 10
		o.BlockOnQueueFull = true
		o.MaxQueueSize = 5000
	}))
	return tracerProvider
}

func randomString(n int) string {
	letters := []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

func runTransactions(tracerProvider *trace.TracerProvider) {
	tracer := tracerProvider.Tracer("otel-tbs-playground")
	ctx := context.Background()
	var wg sync.WaitGroup
	var doneCh = make(chan struct{})
	var slowTxnID, fastTxnID atomic.Int64

	// Slow threads: each sends a slow transaction with configurable duration
	for i := 0; i < *numSlow; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			_, span := tracer.Start(ctx, fmt.Sprintf("slow-transaction-%d", slowTxnID.Add(1)))
			attrs := []attribute.KeyValue{
				attribute.String("thread_id", fmt.Sprintf("slow-%d", id)),
			}
			if *payloadSize > 0 {
				attrs = append(attrs, attribute.String("payload", randomString(*payloadSize)))
			}
			span.SetAttributes(attrs...)
			time.Sleep(*slowDuration)
			span.End()
			fmt.Printf("Slow transaction %d finished\n", id)
			close(doneCh)
		}(i)
	}

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
				attrs := []attribute.KeyValue{
					attribute.String("thread_id", fmt.Sprintf("fast-%d", id)),
				}
				if *payloadSize > 0 {
					attrs = append(attrs, attribute.String("payload", randomString(*payloadSize)))
				}
				span.SetAttributes(attrs...)
				span.End()
				// Optionally, sleep for a tiny amount to avoid overwhelming the exporter
				time.Sleep(10 * time.Millisecond)
			}
		}(i)
	}

	// Wait for all slow transactions to finish, then exit
	wg.Wait()

	fmt.Printf("Sent %d spans\n", slowTxnID.Load()+fastTxnID.Load())
}

func main() {
	flag.Parse()
	tracerProvider := setup()
	defer tracerProvider.Shutdown(context.Background())
	runTransactions(tracerProvider)
}
