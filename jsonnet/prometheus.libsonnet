local prometheus = (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/prometheus.libsonnet');

/**
 * Creates a set of YAML files necessary to run a Prometheus instance using Prometheus-Operator.
 *
 * @param clusterName The name of the cluster where the stack is being deployed to. An external label `cluster` will be configured with the provided value.
 * @param name The name used to create the Prometheus Kubernetes resource.
 * @param namespace The namespace where the Prometheus resource will be deployed to.
 * @param version will populate Prometheus-Operator 'version' field.
 * @param image The Prometheus image used to deploy Prometheus.
 * @param replicas The amount of Prometheus replicas.
 * @param alermanagerName The name of the Alertmanager resource used to route alerts to. If left empty, alerting won't be configured.
 * @param remoteWriteUrl The URL of a remote write endpoint where metrics are going to be sent to. If left empty, remote_write won't be configured.
 * @param commonLabels Labels that will be added to all Prometheus related resources.
 *
 * @method prometheus(params) Creates a Prometheus object.
 */

local defaults = {

  clusterName: error 'must provide clusterName',
  name: error 'must provide name',
  namespace: error 'must provide namespace',
  version: error 'must provide version',
  image: error 'must provide image',
  replicas: error 'must provide replicas',

  alertmanagerName: '',
  remoteWriteUrl: '',

  commonLabels: {},
};


function(params)
  local cfg = defaults + params;

  prometheus(cfg) + {
    // Write extra config to the objects below to override the generated YAMLs
    mixin+: {
      _config+: {
        prometheusSelector: 'job="' + cfg.name + '", namespace="' + cfg.namespace + '"',
        prometheusName: cfg.namespace,
      },
    },
    clusterRole+: {},
    clusterRoleBinding+: {},
    prometheus+: {
      spec+: {
               externalLabels+: {
                 cluster: cfg.clusterName,
               },
             } +
             // Only add alerting config to spec if it was properly set.
             if cfg.alertmanagerName != '' then
               {
                 alerting+: {
                   alertmanagers:
                     std.map(
                       function(a) a {
                         name: cfg.alertmanagerName,
                       },
                       super.alertmanagers,
                     ),
                 },
               } +
               // Only add remote write config to spec if it was properly set.
               if cfg.remoteWriteUrl != '' then
                 {
                   remoteWrite: [{
                     url: cfg.remoteWriteUrl,
                   }],
                 }
               else
                 {},
    },
    prometheusRule+: {},
    service+: {
      metadata+: {
        name: cfg.name,
      },
    },
    serviceAccount+: {},
    serviceMonitor+: {},
  }
