include ./Makefile.Common

# All source code and documents. Used in spell check.
ALL_DOC := $(shell find . \( -name "*.md" -o -name "*.yaml" \) \
                                -type f | sort)

# ALL_MODULES includes ./* dirs with a go.mod file (excludes . and ./_build dirs)
ALL_MODULES := $(shell find . -type f -name "go.mod" -not -wholename "./go.mod" -not -wholename "./_build/*" -exec dirname {} \; | sort )

FIND_INTEGRATION_TEST_MODS={ find . -type f -name "*integration_test.go" & find . -type f -name "*e2e_test.go"; }
TO_MOD_DIR=dirname {} \; | sort | grep -E '^./'
INTEGRATION_MODS := $(shell $(FIND_INTEGRATION_TEST_MODS) | xargs $(TO_MOD_DIR) | uniq)

GROUP ?= all
FOR_GROUP_TARGET=for-$(GROUP)-target

.DEFAULT_GOAL := all

.PHONY: all
all: misspell

# Append root module to all modules
GOMODULES = $(ALL_MODULES)

# Define a delegation target for each module
.PHONY: $(GOMODULES)
$(GOMODULES):
	@echo "Running target '$(TARGET)' in module '$@'"
	$(MAKE) -C $@ $(TARGET)

# Triggers each module's delegation target
.PHONY: for-all-target
for-all-target: $(GOMODULES)

.PHONY: for-integration-target
for-integration-target: $(INTEGRATION_MODS)

.PHONY: gomoddownload
gomoddownload:
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="moddownload"

.PHONY: gotest
gotest:
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="test"

.PHONY: gointegration-test
gointegration-test:
	@$(MAKE) for-integration-target TARGET="integration-test"

.PHONY: golint
golint:
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="lint"

.PHONY: golicense
golicense:
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="license-check"

.PHONY: gofmt
gofmt:
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="fmt"

.PHONY: gotidy
gotidy:
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="tidy"

.PHONY: gogenerate
gogenerate:
	# This is a workaround for a bug in mdatagen upstream: https://github.com/open-telemetry/opentelemetry-collector/issues/13069
	@command -v goimports >/dev/null 2>&1 || $(MAKE) -B install-tools
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="generate"
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="fmt"

.PHONY: gogovulncheck
gogovulncheck:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="govulncheck"

.PHONY: goporto
goporto:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="porto"

.PHONY: remove-toolchain
remove-toolchain:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="toolchain"

# Build a collector based on the Elastic components (generate Elastic collector)
.PHONY: build
build: $(BUILDER)
	GOOS=${TARGET_GOOS} GOARCH=${TARGET_GOARCH} $(BUILDER) --config ./manifest.yaml

# Validate that the Elastic components collector can run with the example configuration.
.PHONY: validate
validate: build
	./_build/otel-tbs-playground validate --config ./tail.yaml
