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

if [[ ${IS_PREVIEW_ENV:-false} == false ]]; then
  kubectl delete \
	-f manifests/node-exporter/ \
	-f manifests/kube-state-metrics/ \
	-f manifests/alertmanager/ \
    -f manifests/grafana/ \
	-f manifests/kubernetes/

fi

# Prometheus instance and namespace are present for both preview environments
# and full-cluster o11y stacks.
kubectl delete manifests/prometheus/

if [[ ${IS_PREVIEW_ENV:-false} == false ]]; then
  kubectl delete -f manifests/prometheus-operator/

  if [[ ${DELETE_CRD:-false} == true ]]; then
    kubectl delete -f manifests/prometheus-operator/setup
  fi
fi

kubectl delete -f manifests/namespace.yaml