local prometheus = (import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/prometheus.libsonnet');

/**
 * Creates a set of YAML files necessary to run a Prometheus instance using Prometheus-Operator.
 *
 * @param clusterName(Required) The name of the cluster where the stack is being deployed to. An external label `cluster` will be configured with the provided value.
 * @param name(Required) The name used to create the Prometheus Kubernetes resource.
 * @param namespace(Required) The namespace where the Prometheus resource will be deployed to.
 * @param version(Required) will populate Prometheus-Operator 'version' field.
 * @param image(Required) The Prometheus image used to deploy Prometheus.
 * @param replicas(Required) The amount of Prometheus replicas.
 * @param alermanagerName(Optional) The name of the Alertmanager resource used to route alerts to. If left empty, alerting won't be configured.
 * @param remoteWriteUrl(Optional) The URL of a remote write endpoint where metrics are going to be sent to. If left empty, remote_write won't be configured.
 * @param commonLabels(Optional) Labels that will be added to all Prometheus related resources.
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
    clusterRole+: {
      rules+: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: ['prometheus-psp'],
      }],
    },
    clusterRoleBinding+: {},
    podSecurityPolicy: {
      apiVersion: 'policy/v1beta1',
      kind: 'PodSecurityPolicy',
      metadata: {
        name: 'prometheus-psp',
      },
      spec: {
        allowPrivilegeEscalation: false,
        privileged: false,
        hostNetwork: false,
        hostPID: false,
        runAsUser: {
          rule: 'MustRunAsNonRoot',
        },
        seLinux: {
          rule: 'RunAsAny',
        },
        hostPorts: [
          {
            max: 65535,
            min: 1,
          },
        ],
        fsGroup: {
          ranges: [
            {
              max: 65535,
              min: 1,
            },
          ],
          rule: 'MustRunAs',
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
          'secret',
          'emptyDir',
        ],
      },
    },

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
