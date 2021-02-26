local kubernetes = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/k8s-control-plane.libsonnet';

function(params)
  local cfg = params;
  
  kubernetes(cfg) {
      // Write extra config to the objects below to override the generated YAMLs.
      mixin+: {
          _config+:{
              // On GKE, kube-controller-manager metrics are exposed by Apiserver
              kubeControllerManagerSelector: 'job="apiserver"'
          },
      },
      prometheusRule+:{
          // TODO(arthursens): maybe there is no need to change the namespace, needs triage
          metadata+: {
              namespace: cfg.prometheusNamespace,
          },
      },
      serviceMonitorApiserver+:{},
      // Disabling ServiceMonitor for CoreDNS, since we don't use it.
      serviceMonitorCoreDNS+:: {},
      // Controller manager is unacessible on GKE.
      serviceMonitorKubeControllerManager+:: {},
      serviceMonitorKubelet+: {},
      serviceMonitorKubeScheduler+:{},
  }