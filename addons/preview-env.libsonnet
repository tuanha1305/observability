// Preview environments are supposed to gather metrics only from the Gitpod
// installation it is responsible for. There is no need to add dashboards that aren't
// Prometheus or Gitpod related.

{
  values+:: {
    prometheus+: {
      name: 'preview-environment',
    },
    grafana+: {
      dashboards: $.prometheus.mixin.grafanaDashboards,
    },
  },
}
