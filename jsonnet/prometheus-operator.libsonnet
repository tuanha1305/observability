local operator = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/prometheus-operator.libsonnet';

function(params)
  local cfg = params;
  operator(cfg) + {

    // Write extra config to the objects below to override the generated YAMLs
    clusterRole+: {},
    clusterRoleBinding+: {},
    deployment+: {},
    prometheusRule+: {},
    service+: {},
    serviceAccount+: {},
    serviceMonitor+: {},
  }
