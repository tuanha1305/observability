BIN_DIR?=$(shell pwd)/tmp/bin
JB_BIN=$(BIN_DIR)/jb
GOJSONTOYAML_BIN=$(BIN_DIR)/gojsontoyaml
JSONNET_BIN=$(BIN_DIR)/jsonnet
JSONNETFMT_BIN=$(BIN_DIR)/jsonnetfmt
TOOLING=$(JSONNETFMT_BIN) $(JSONNET_BIN) $(GOJSONTOYAML_BIN) $(JB_BIN)

JSONNET_FMT := $(JSONNETFMT_BIN) -n 2 --max-blank-lines 2 --string-style s --comment-style s

all: setup-workspace vendor gitpod-mixin fmt lint 

.PHONY: clean
clean:
    # Delete files marked in .gitignore
	git clean -Xfd .

.PHONY: setup-workspace
setup-workspace: 
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
	go get github.com/brancz/gojsontoyaml
	go get github.com/google/go-jsonnet/cmd/jsonnet
	go get github.com/google/go-jsonnet/cmd/jsonnetfmt
	GO111MODULE=on go get github.com/prometheus/prometheus/cmd/promtool@release-2.26
	export PATH=$(PATH):$(PWD)/tmp/bin

vendor: $(JB_BIN)
	$(JB_BIN) init
	$(JB_BIN) install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@main

.PHONY: build
build: 
	./hack/build.sh monitoring-satellite/main.jsonnet

.PHONY: build-monitoring-central
build-monitoring-central: 
	./hack/build.sh monitoring-central/monitoring-central.jsonnet

.PHONY: deploy
deploy: 
	./hack/deploy.sh

.PHONY: deploy-monitoring-central
deploy-monitoring-central: 
	kubectl apply -f manifests/grafana/ -f manifests/victoriametrics/

.PHONY: delete
delete: 
	./hack/delete.sh

.PHONY: delete-monitoring-central
delete-monitoring-central: 
	kubectl delete -f manifests/grafana/ -f manifests/victoriametrics/

.PHONY: gitpod-mixin
gitpod-mixin: $(JSONNET_BIN)
	cd components/gitpod/mixin && $(JSONNET_BIN) -S rules.jsonnet > prometheus_rules.yaml

.PHONY: fmt
fmt: $(JSONNETFMT_BIN)
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNET_FMT) -i

.PHONY: lint
lint: $(JSONNETFMT_BIN) gitpod-mixin
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		while read f; do \
			$(JSONNET_FMT) "$$f" | diff -u "$$f" -; \
		done

.PHONY: promtool-lint
promtool-lint: 
	promtool check rules components/gitpod/mixin/prometheus_rules.yaml

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(TOOLING): $(BIN_DIR)
	@echo Installing tools from tools.go
	@cd hack && cat tools.go | grep _ | awk -F'"' '{print $$2}' | xargs -tI % go build -modfile=go.mod -o $(BIN_DIR) %