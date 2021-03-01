local nodeExporter = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/node-exporter.libsonnet';

/**
 * Creates a set of YAML files necessary to run Prometheus' node-exporter on Kubernetes.
 *
 * @param namespace(Required) The namespace where node-exporter will be deployed to.
 * @param version(Required) Required by kube-prometheus node-exporter library.
 * @param image(Required) The node-exporter image used to deploy node-exporter.
 * @param commonLabels(Optional) Labels that will be added to all node-exporter related resources.
 *
 * @method nodeExporter(params) Creates a NodeExporter object.
 */

local defaults = {

  namespace: error 'must provide namespace',
  version: error 'must provide version',
  image: error 'must provide image',

};

function(params)
  local cfg = defaults + params;

  nodeExporter(cfg) {

    // Write extra config to the objects below to override the generated YAMLs
    clusterRole+: {
      rules+: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: ['node-exporter-psp'],
      }],
    },
    clusterRoleBinding+: {},
    podSecurityPolicy: {
      apiVersion: 'policy/v1beta1',
      kind: 'PodSecurityPolicy',
      metadata: {
        name: 'node-exporter-psp',
      },
      spec: {
        allowedHostPaths: [
          {
            pathPrefix: '/proc',
            readOnly: true,
          },
          {
            pathPrefix: '/sys',
            readOnly: true,
          },
          {
            pathPrefix: '/',
            readOnly: true,
          },
        ],
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
          'configMap',
          'hostPath',
          'secret',
        ],
      },
    },
    daemonset+: {
      spec+: {
        updateStrategy+: {
          rollingUpdate+: {
            // The default value is '10%'.
            maxUnavailable: 1,
          },
        },
      },
    },
    prometheusRule+: {},
    service+: {},
    serviceAccount+: {},
    serviceMonitor+: {},
  }
