JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s

all: fmt prometheus_rules.yaml lint

fmt:
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNET_FMT) -i

.PHONY: prometheus_rules.yaml
prometheus_rules.yaml: mixin.libsonnet rules.libsonnet
	jsonnet -S rules.jsonnet > prometheus_rules.yaml

lint: prometheus_rules.yaml
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		while read f; do \
			$(JSONNET_FMT) "$$f" | diff -u "$$f" -; \
		done

	promtool check rules prometheus_rules.yaml

clean:
	rm -rf prometheus_rules.yaml