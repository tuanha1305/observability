#!/usr/bin/env bash

########################################################################
# Before calling this utility script, make sure your KUBECONFIG is 
# correctly configured and that the manifests were generated already.
#
# Your context should be directed to the cluster that you want to delete
# the observability stack.
#
# To have a complete deletion, the exact same manifests used to deploy 
# the stack need to be used here.
########################################################################
set -x

# The delete process is pretty simple, delete everything but leave the
# Prometheus-Operator deployment and CRDs at last.
#
# One can also optionally keep the CRDs installed, so a future redeploy 
# is quicker.

kubectl delete \
	-f manifests/node-exporter/ \
	-f manifests/kube-state-metrics/ \
	-f manifests/prometheus/ \
	-f manifests/alertmanager/

kubectl delete -f manifests/prometheus-operator/
kubectl delete -f manifests/namespace.yaml

if [[ ${DELETE_CRD:-false} == true ]]; then
  kubectl delete -f manifests/prometheus-operator/setup
fi

if [[ ${INCLUDE_GRAFANA:-false} == true ]]; then
  kubectl delete -f manifests/grafana
fi