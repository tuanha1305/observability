local tmpVolumeName = 'volume-directive-shadow';
local tlsVolumeName = 'kube-state-metrics-tls';

local kubeStateMetrics = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/kube-state-metrics.libsonnet';

function(params) 
  local cfg = params;

  kubeStateMetrics(cfg) + {
    // Write extra config to the objects below to override the generated YAMLs 
    clusterRole+: {},
    clusterRoleBinding+: {},
    deployment+: {},
    prometheusRule+: {},
    service+: {},
    serviceAccount+: {},
    serviceMonitor+: {},
}