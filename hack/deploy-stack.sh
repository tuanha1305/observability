#!/usr/bin/env bash

########################################################################
# Before calling this utility script, make sure your KUBECONFIG is 
# correctly configured and that the manifests were generated already.
#
# Your context should be directed to the cluster that you want to deploy
# the observability stack.
#
# One can generate the stack manifests with 'make build-stack'.
########################################################################
set -x

# The first thing that needs to be deployed are Prometheus-Operator CRDs,
# but first check if the CRDs aren't present already. Reapplying the same
# CRD causes a lot of stress on the client machine and the whole operation
# is extremelly slow.

# Prometheus CRD
kubectl get crd prometheuses.monitoring.coreos.com >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/prometheus-operator/setup/0prometheusCustomResourceDefinition.yaml
fi

# PrometheusRule CRD
kubectl get crd prometheusrules.monitoring.coreos.com >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/prometheus-operator/setup/0prometheusruleCustomResourceDefinition.yaml
fi

# ServiceMonitor CRD
kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/prometheus-operator/setup/0servicemonitorCustomResourceDefinition.yaml
fi

# PodMonitor CRD
kubectl get crd podmonitors.monitoring.coreos.com >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/prometheus-operator/setup/0podmonitorCustomResourceDefinition.yaml
fi

# Alertmanager CRD
kubectl get crd alertmanagers.monitoring.coreos.com >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/prometheus-operator/setup/0alertmanagerCustomResourceDefinition.yaml
fi

# AlertmanagerConfig CRD
kubectl get crd alertmanagerconfigs.monitoring.coreos.com >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/prometheus-operator/setup/0alertmanagerConfigCustomResourceDefinition.yaml
fi


# Even though we might not use Probe and ThanosRuler CRDs
# the operator need that those CRDs exist. The operator gets stuck
# and don't deploy anything otherwise
#
# Probe CRD
kubectl get crd probes.monitoring.coreos.com >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/prometheus-operator/setup/0probeCustomResourceDefinition.yaml
fi

# ThanosRuler CRD
kubectl get crd thanosrulers.monitoring.coreos.com >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/prometheus-operator/setup/0thanosrulerCustomResourceDefinition.yaml
fi


# Create namespace if it doesn't exist
# Preview environment namespaces usually do.
kubectl get ns ${NAMESPACE:-monitoring} >/dev/null 2>&1
exist=$?
if [[ $exist == 1 ]]; then
  kubectl apply -f manifests/namespace.yaml
fi

# Prometheus-operator should be present on the cluster prior to setting up
# an o11y stack to a preview environment.
if [[ ${IS_PREVIEW_ENV:-false} == false ]]; then
  kubectl apply \
    -f manifests/prometheus-operator/serviceAccount.yaml \
    -f manifests/prometheus-operator/clusterRole.yaml \
    -f manifests/prometheus-operator/clusterRoleBinding.yaml \
    -f manifests/prometheus-operator/deployment.yaml 
  
  kubectl rollout status -n ${NAMESPACE:-monitoring} deployment prometheus-operator
  kubectl apply \
    -f manifests/prometheus-operator/service.yaml \
    -f manifests/prometheus-operator/serviceMonitor.yaml \
    -f manifests/prometheus-operator/prometheusRule.yaml


  # After the operator is succesfully deployed, everything else can be safely deployed.
  # If it is a preview environment, almost all of these directories are empty.
  kubectl apply \
  	-f manifests/node-exporter/ \
  	-f manifests/kube-state-metrics/ \
  	-f manifests/alertmanager/ \
    -f manifests/kubernetes/ \
    -f manifests/grafana/
    kubectl rollout status -n ${NAMESPACE:-monitoring} deployment kube-state-metrics
    kubectl rollout status -n ${NAMESPACE:-monitoring} daemonset node-exporter
fi 

# Prometheus is the only common thing that is deployed to preview environments
# and to full-cluster monitoring.
kubectl apply -f manifests/prometheus/ 