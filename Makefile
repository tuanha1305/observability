setup-workspace: 
	go get github.com/google/go-jsonnet/cmd/jsonnet
	go get github.com/google/go-jsonnet/cmd/jsonnetfmt
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
	go get github.com/brancz/gojsontoyaml
	jb init
	jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@release-0.7
	wget https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/release-0.7/build.sh -O build.sh 
	chmod +x build.sh
	./build.sh o11y-stack.jsonnet