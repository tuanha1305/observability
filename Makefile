setup-workspace: 
	go get github.com/google/go-jsonnet/cmd/jsonnet
	go get github.com/google/go-jsonnet/cmd/jsonnetfmt
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
	go get github.com/brancz/gojsontoyaml
	jb init
	jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@main

build-stack:
	./hack/build.sh jsonnet/main.jsonnet

build-grafana:
	./hack/build.sh grafana.jsonnet

deploy-stack: 
	./hack/deploy-stack.sh

delete-stack: 
	./hack/delete-stack.sh
