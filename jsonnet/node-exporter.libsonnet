local nodeExporter = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/node-exporter.libsonnet';

function(params) 
  local cfg = params;

  nodeExporter(cfg) {

  // Write extra config to the objects below to override the generated YAMLs 
  clusterRole+: {},
  clusterRoleBinding+: {},
  daemonset+: {},
  prometheusRule+: {},
  service+: {},
  serviceAccount+: {},
  serviceMonitor+: {},
}