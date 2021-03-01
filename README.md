# pluggable-o11y-stack
Utility scripts that deploys an opinionated observability stack into a kubernetes cluster. Focused on monitoring [Gitpod](https://github.com/gitpod-io/gitpod).

## Building YAML files

To generate all YAML files needed to deploy the stack, run:
```
make build
```

The default namespace where the stack is deployed is `cluster-monitoring`. One can change the namespace by declaring a `NAMESPACE` variable:
```
NAMESPACE=my-custom-namespace make build
```

When deploying the stack to preview environments, where the insterest is just to observe the custom Gitpod installation, one can optionally generate only the YAML files related to prometheus with the `IS_PREVIEW_ENV` variable:
```
IS_PREVIEW_ENV=true make build
```

## Deploying the stack

Make sure you have your `.kubeconfig` properly configured and pointing to the cluster where you wanna deploy the stack, then run:
```
make deploy
```

Keep in mind that if you've generated the files with some customization, you'll need to apply the same variables when deploying. One strategy would be:
```
export NAMESPACE=my_custom_namespace
export IS_PREVIEW_ENV=true
make build && make deploy
```

The reason for repeating those variables to the deploy step is to perform some deployment sanity checks. If interested, you can take a look at the deployment script [hack/deploy.sh](hack/deploy.sh).

## Deleting the stack

Similar to the deployment strategy.
```
export NAMESPACE=my_custom_namespace
export IS_PREVIEW_ENV=true
make build && make delete
```

The default behavior won't delete the Prometheus-Operator CRDs though. If you'd like to delete them as well, run:
```
export NAMESPACE=my_custom_namespace
export IS_PREVIEW_ENV=true
export DELETE_CRD=true
make build && make delete
```

## Contributing

### Setup environment

To be able to develop and use this repository, you'll need a couple of tools and binaries installed. Make sure you have [Go](https://golang.org/doc/install) and then run:
```
go get github.com/google/go-jsonnet/cmd/jsonnet
go get github.com/google/go-jsonnet/cmd/jsonnetfmt
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
go get github.com/brancz/gojsontoyaml
jb init
jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@main
```
Or:
```
make setup-workspace
```
Which will run the exact same commands.

Alternatively, you can develop and use this repository on Gitpod, which will create a disposable developer environment with everything installed.

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/ArthurSens/pluggable-o11y-stack)


> Please remember to always run `make fmt` before sending a PR!!