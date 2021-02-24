setup-workspace: 
	go get github.com/google/go-jsonnet/cmd/jsonnet
	go get github.com/google/go-jsonnet/cmd/jsonnetfmt
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
	go get github.com/brancz/gojsontoyaml
	jb init
	jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@main

build-stack:
	./build.sh jsonnet/main.jsonnet

build-grafana:
	./build.sh grafana.jsonnet

apply-stack: 
	# TODO: shell script that creates everything on the right order
	# while waiting for the right components to be ready
	kubectl apply \
	-f manifests/prometheus-operator/deployment.yaml \
	-f manifests/prometheus-operator/ \
	-f manifests/node-exporter/ \
	-f manifests/kube-state-metrics/ \
	-f manifests/prometheus/ \
	-f manifests/alertmanager

delete-stack: 
	kubectl delete \
	-f manifests/node-exporter/ \
	-f manifests/kube-state-metrics/ \
	-f manifests/prometheus-operator/ \
	-f manifests/prometheus/ \
	-f manifests/alertmanager
