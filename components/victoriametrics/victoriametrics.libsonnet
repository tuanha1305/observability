local defaults = {
  local defaults = self,


  name: 'victoriametrics',
  namespace: 'monitoring-central',
  version: 'v1.47.0',
  port: 8428,
  internalLoadBalancerIP: error 'must provide internal load balancer ip address',
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'monitoring-central',
  },
};

function(params) {
  local v = self,
  _config:: defaults + params,

  clusterRole: {
    apiVersion: 'rbac.authorization.k8s.io/v1beta1',
    kind: 'ClusterRole',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
    },
    rules: [{
      apiGroups: ['policy'],
      resources: ['podsecuritypolicies'],
      verbs: ['use'],
      resourceNames: [v.podSecurityPolicy.metadata.name],
    }],
  },

  clusterRoleBinding: {
    apiVersion: 'rbac.authorization.k8s.io/v1beta1',
    kind: 'ClusterRoleBinding',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
    },
    subjects: [{
      kind: 'ServiceAccount',
      name: v.serviceAccount.metadata.name,
      namespace: $._config.namespace,
    }],
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: v.clusterRole.metadata.name,
    },
  },

  podSecurityPolicy: {
    apiVersion: 'policy/v1beta1',
    kind: 'PodSecurityPolicy',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
    },
    spec: {
      privileged: false,
      seLinux: {
        rule: 'RunAsAny',
      },
      supplementalGroups: {
        rule: 'RunAsAny',
      },
      runAsUser: {
        rule: 'RunAsAny',
      },
      fsGroup: {
        rule: 'RunAsAny',
      },
      volumes: ['*'],
    },
  },

  serviceAccount: {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
      namespace: $._config.namespace,
    },
  },

  statefulSet: {
    apiVersion: 'apps/v1',
    kind: 'StatefulSet',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
      namespace: $._config.namespace,
    },
    spec: {
      selector: {
        matchLabels: $._config.commonLabels,
      },
      serviceName: $._config.name,
      replicas: 1,
      template: {
        metadata: {
          labels: $._config.commonLabels,
        },
        spec: {
          securityContext: {
            fsGroup: 65534,
            runAsGroup: 65534,
            runAsNonRoot: true,
            runAsUser: 65534,
          },
          terminationGracePeriodSeconds: 300,
          serviceAccountName: v.serviceAccount.metadata.name,
          containers: [{
            name: $._config.name,
            image: 'victoriametrics/victoria-metrics:' + $._config.version,
            imagePullPolicy: 'IfNotPresent',
            args: [],
            ports: [{
              containerPort: $._config.port,
            }],
            readinessProbe: {
              httpGet: {
                path: '/metrics',
                port: $._config.port,
              },
              initialDelaySeconds: 30,
              timeoutSeconds: 30,
              failureThreshold: 3,
              successThreshold: 1,
            },
            livenessProbe: {
              httpGet: {
                path: '/metrics',
                port: $._config.port,
              },
              initialDelaySeconds: 30,
              timeoutSeconds: 30,
              failureThreshold: 3,
              successThreshold: 1,
            },
            resources: {},
            volumeMounts: [{
              name: 'storage-volume',
              mountPath: '/victoria-metrics-data',
              subPath: '',
            }],
          }],
        },
      },
      volumeClaimTemplates: [{
        metadata: {
          name: 'storage-volume',
        },
        spec: {
          accessModes: ['ReadWriteOnce'],
          resources: {
            requests: {
              storage: '500Gi',
            },
          },
        },
      }],
    },
  },

  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
      namespace: $._config.namespace,
      annotations: {
        // Needed to automatically create a global load balancer on GKE.
        'networking.gke.io/load-balancer-type': 'Internal',
        'networking.gke.io/internal-load-balancer-allow-global-access': 'true',
      },
    },
    spec: {
      type: 'LoadBalancer',
      loadBalancerIP: $._config.internalLoadBalancerIP,
      ports: [{
        port: $._config.port,
        targetPort: $._config.port,
        protocol: 'TCP',
        name: 'http',
      }],
      selector: $._config.commonLabels,
    },
  },

}
