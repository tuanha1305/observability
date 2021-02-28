local prometheus = 
  (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/prometheus.libsonnet'); //+
  // TODO: conditionally add this part
  //(import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/addons/all-namespaces.libsonnet');

  local defaults = {
    local defaults = self,

    namespace: error 'must provide namespace',
    name: error 'must provide name',
    version: error 'must provide version',
    image: error 'must provide image',
    replicas: error 'must provide replicas',
    clusterName: error 'must provide clusterName',

    alertmanagerName: error 'must provide alertmanagerName',
    remoteWriteUrl: '',


    commonLabels: {},
  };




function(params)
  local cfg = defaults + params;

  prometheus(cfg) + {
  // Write extra config to the objects below to override the generated YAMLs 
  mixin+:{
    _config+:{
      prometheusSelector: 'job="' + cfg.name + '", namespace="' + cfg.namespace + '"',
      prometheusName: cfg.namespace,
    },
  },
  clusterRole+: {},
  clusterRoleBinding+: {},
  prometheus+: {
      spec+: {
          alerting+: {
              alertmanagers: 
              std.map(
                  function(a) a {
                      name: cfg.alertmanagerName,
                  },
                  super.alertmanagers,
              ),
          },
          externalLabels+: {
            cluster: cfg.clusterName,
          }, 
      } + 
      // Only add remote write config to spec if it was properly set
      if cfg.remoteWriteUrl != '' then
        {
          remoteWrite: [{
            url: cfg.remoteWriteUrl,
          }],
        }
      else
          {},
  },
  prometheusRule+:{},
  service+: {
      metadata+: {
        name: cfg.name
      },
  },
  serviceAccount+: {},
  serviceMonitor+: {},
}