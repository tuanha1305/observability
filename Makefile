setup-workspace: 
	go get github.com/google/go-jsonnet/cmd/jsonnet
	go get github.com/google/go-jsonnet/cmd/jsonnetfmt
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
	go get github.com/brancz/gojsontoyaml
	jb init
	jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@c0341d3667e86e52ec3a4b438eaa7f2688aaaf37

build:
	./hack/build.sh main.jsonnet

deploy: 
	./hack/deploy.sh

delete: 
	./hack/delete.sh

fmt:
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s -i
