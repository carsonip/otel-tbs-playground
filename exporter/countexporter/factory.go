package countexporter

import (
	"context"

	"go.opentelemetry.io/collector/component"
	"go.opentelemetry.io/collector/exporter"
	"go.opentelemetry.io/collector/exporter/exporterhelper"

	"github.com/carsonip/otel-tbs-playground/exporter/countexporter/internal/metadata"
)

type Config struct{}

func NewFactory() exporter.Factory {
	return exporter.NewFactory(
		metadata.Type,
		createDefaultConfig,
		exporter.WithTraces(createTracesExporter, metadata.TracesStability),
	)
}

func createDefaultConfig() component.Config {
	return &Config{}
}

func createTracesExporter(
	ctx context.Context,
	set exporter.Settings,
	cfg component.Config,
) (exporter.Traces, error) {
	exp := New()
	return exporterhelper.NewTraces(
		ctx,
		set,
		cfg,
		exp.ConsumeTraces,
		exporterhelper.WithShutdown(exp.Shutdown),
	)
}
