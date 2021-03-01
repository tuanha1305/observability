local kubeStateMetrics = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/kube-state-metrics.libsonnet';

/**
 * Creates a set of YAML files necessary to run kube-state-metrics.
 *
 * @param namespace(Required) The namespace where kube-state-metrics will be deployed to.
 * @param version(Required) Required by kube-prometheus kube-state-metrics library.
 * @param image(Required) The kube-state-metrics image used to deploy kube-state-metrics.
 * @param commonLabels(Optional) Labels that will be added to all kube-state-metrics related resources.
 *
 * @method nodeExporter(params) Creates a KubeStateMetrics object.
 */

local defaults = {

  namespace: error 'must provide namespace',
  version: error 'must provide version',
  image: error 'must provide image',

  commonLabels: {},
};

function(params)
  local cfg = defaults + params;

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
