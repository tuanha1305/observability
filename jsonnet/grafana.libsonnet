local grafana = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/grafana.libsonnet';

function(params)
  local cfg = params;
  grafana(cfg) {

    // PodSecurityPolicies are not implemented on kube-prometheus yet. So we need to create them ourselves.
    // Or we could contribute to their project :)
    // See: https://github.com/prometheus-operator/kube-prometheus/issues/572
    clusterRole: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRole',
      metadata: {
        name: 'grafana-' + cfg.namespace,
      },
      rules: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: ['grafana-' + cfg.namespace + '-psp'],
      }],
    },
    clusterRoleBinding: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRoleBinding',
      metadata: {
        name: 'grafana-' + cfg.namespace,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'ClusterRole',
        name: 'grafana-' + cfg.namespace,
      },
      subjects: [{
        kind: 'ServiceAccount',
        name: 'grafana-' + cfg.namespace,
        namespace: cfg.namespace,
      }],
    },
    podSecurityPolicy: {
      apiVersion: 'policy/v1beta1',
      kind: 'PodSecurityPolicy',
      metadata: {
        name: 'grafana-' + cfg.namespace + '-psp',
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
          'emptyDir'
        ],
      },
    },

    serviceMonitor+: {},
    serviceAccount+: {
      metadata+: {
        name: 'grafana-' + cfg.namespace,
      },
    },
    service+: {},
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            serviceAccountName: 'grafana-' + cfg.namespace,
          },
        },
      },
    },
  }
