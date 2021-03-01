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

};

function(params)
  local cfg = defaults + params;

  kubeStateMetrics(cfg) + {
    // Write extra config to the objects below to override the generated YAMLs
    clusterRole+: {
      rules+: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: ['kube-state-metrics-psp'],
      }],
    },
    clusterRoleBinding+: {},
    podSecurityPolicy: {
      apiVersion: 'policy/v1beta1',
      kind: 'PodSecurityPolicy',
      metadata: {
        name: 'kube-state-metrics-psp',
      },
      spec: {
        allowPrivilegeEscalation: false,
        fsGroup: {
          ranges: [
            {
              max: 65535,
              min: 1,
            },
          ],
          rule: 'MustRunAs',
        },
        hostIPC: false,
        hostNetwork: true,
        hostPID: true,
        hostPorts: [
          {
            max: 65535,
            min: 1,
          },
        ],
        privileged: false,
        readOnlyRootFilesystem: false,
        requiredDropCapabilities: [
          'ALL',
        ],
        runAsUser: {
          rule: 'RunAsAny',
        },
        seLinux: {
          rule: 'RunAsAny',
        },
        supplementalGroups: {
          ranges: [
            {
              max: 65535,
              min: 1,
            },
          ],
          rule: 'MustRunAs',
        },
        volumes: [
          'secret',
        ],
      },
    },
    deployment+: {},
    prometheusRule+: {},
    service+: {},
    serviceAccount+: {},
    serviceMonitor+: {},
  }
