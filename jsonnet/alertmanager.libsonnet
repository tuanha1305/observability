local alertmanager = import 'github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus/components/alertmanager.libsonnet';

function(params)
  local cfg = params;

  alertmanager(cfg) {
    // Write extra config to the objects below to override the generated YAMLs

    // PodSecurityPolicies are not implemented on kube-prometheus yet. So we need to create them ourselves.
    // Or we could contribute to their project :)
    // See: https://github.com/prometheus-operator/kube-prometheus/issues/572
    clusterRole: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRole',
      metadata: {
        name: 'alertmanager-' + cfg.namespace,
      },
      rules: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: ['alertmanager-' + cfg.namespace + '-psp'],
      }],
    },
    clusterRoleBinding: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRoleBinding',
      metadata: {
        name: 'alertmanager-' + cfg.namespace,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'ClusterRole',
        name: 'alertmanager-' + cfg.namespace,
      },
      subjects: [{
        kind: 'ServiceAccount',
        name: 'alertmanager-' + cfg.namespace,
        namespace: cfg.namespace,
      }],
    },

    podSecurityPolicy: {
      apiVersion: 'policy/v1beta1',
      kind: 'PodSecurityPolicy',
      metadata: {
        name: 'alertmanager-' + cfg.namespace + '-psp',
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

    alertmanager+: {
        spec+: {
            serviceAccountName: 'alertmanager-' + cfg.namespace,
        },
    },
    prometheusRule+: {},
    secret+: {},
    service+: {
      metadata+: {
        // to align with the change made at prometheus.libsonnet
        name: cfg.name,
      },
    },
    serviceAccount+: {
      metadata+: {
        name: 'alertmanager-' + cfg.namespace,
      },
    },
    serviceMonitor+: {},
  }
