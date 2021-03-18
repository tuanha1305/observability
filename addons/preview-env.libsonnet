// The preview-environment addon provides json snippets that are specific for preview environment installations.
{
  values+:: {
    prometheus+: {
      name: 'preview-environment',
      namespaces: [std.extVar('namespace')],
    },
    grafana+: {
      dashboards: $.prometheus.mixin.grafanaDashboards + $.gitpod.mixin.grafanaDashboards,
    },
  },

  prometheus+: {
    prometheus+: {
      spec+: {
        serviceMonitorNamespaceSelector: {
          matchLabels: {
            namespace: std.extVar('namespace'),
          },
        },
      },
    },
  },

  kubePrometheus+: {
    namespace+: {
      metadata+: {
        labels+: {
          namespace: std.extVar('namespace'),
        },
      },
    },
  },
}
