{
  prometheus+: {
    prometheus+: {
      spec+: {
        nodeSelector+: {
          'cloud.google.com/gke-nodepool': 'monitoring-pool-0',
        },
      },
    },
  },

  alertmanager+: {
    alertmanager+: {
      spec+: {
        nodeSelector+: {
          'cloud.google.com/gke-nodepool': 'monitoring-pool-0',
        },
      },
    },
  },

  grafana+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            nodeSelector+: {
              'cloud.google.com/gke-nodepool': 'monitoring-pool-0',
            },
          },
        },
      },
    },
  },

  prometheusOperator+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            nodeSelector+: {
              'cloud.google.com/gke-nodepool': 'monitoring-pool-0',
            },
          },
        },
      },
    },
  },

  kubeStateMetrics+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            nodeSelector+: {
              'cloud.google.com/gke-nodepool': 'monitoring-pool-0',
            },
          },
        },
      },
    },
  },
}
