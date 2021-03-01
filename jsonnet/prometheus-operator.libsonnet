local operator = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/prometheus-operator.libsonnet';

/**
 * Creates a set of YAML files necessary to run Prometheus-Operator.
 *
 * @param namespace(Required) The namespace where prometheus-operator will be deployed to.
 * @param version(Required) Required by kube-prometheus prometheus-operator library.
 * @param image(Required) The prometheus-operator image used to deploy prometheus-operator.
 * @param configReloaderImage(Required) The image used to deploy prometheus-config-reloader.
 * @param commonLabels(Optional) Labels that will be added to all node-exporter related resources.
 *
 * @method nodeExporter(params) Creates a NodeExporter object.
 */

local defaults = {

  namespace: error 'must provide namespace',
  version: error 'must provide version',
  image: error 'must provide image',
  configReloaderImage: error 'must provide configReloaderImage',

  commonLabels: {},
};

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
