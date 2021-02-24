local alertmanager = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/alertmanager.libsonnet';

function(params)
  local cfg = params;
  
  alertmanager(cfg) {
    // Write extra config to the objects below to override the generated YAMLs 
    alertmanager+: {},
    prometheusRule+: {},
    secret+: {},
    service+: {
      metadata+: {
        name: cfg.name
      },
    },
    serviceAccount+: {},
    serviceMonitor+: {},
}