local prometheus = 
  (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/prometheus.libsonnet'); //+
  // TODO: conditionally add this part
  //(import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/addons/all-namespaces.libsonnet');

function(params)
  local cfg = params;

  prometheus(cfg) + {
  // Write extra config to the objects below to override the generated YAMLs 
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
      },
  },
  prometheusRule+:{},
  service+: {},
  serviceAccount+: {},
  serviceMonitor+: {},
}