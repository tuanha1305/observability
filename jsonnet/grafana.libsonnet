local grafana = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/grafana.libsonnet';

function(params)
  local cfg = params;
  grafana(cfg) {

    serviceMonitor+: {},
    serviceAccount+: {},    
    service+: {},
    deployment+: {},
}