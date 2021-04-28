local gitpod = import '../components/gitpod/gitpod.libsonnet';

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/platforms/gke.libsonnet') +
  (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
  (import '../addons/disable-grafana-auth.libsonnet') +
  (import 'kube-prometheus/addons/strip-limits.libsonnet') +
  (import '../addons/gitpod-runbooks.libsonnet') +
  (if std.extVar('remote_write_url') != '' then (import '../addons/remote-write.libsonnet') else {}) +
  (if std.extVar('slack_webhook_url_critical') != '' then (import '../addons/slack-alerting.libsonnet') else {}) +
  (if std.extVar('dns_name') != '' then (import '../addons/grafana-on-gcp-oauth.libsonnet') else {}) +
  (if std.extVar('is_preview_env') then (import '../addons/preview-env.libsonnet') else (import '../addons/cluster-monitoring.libsonnet'))
  {
    values+:: {
      common+: {
        namespace: std.extVar('namespace'),
      },

      gitpodParams: {
        namespace: std.extVar('namespace'),
        gitpodNamespace: 'default',
        prometheusLabels: $.prometheus.prometheus.metadata.labels,
        mixin+: { ruleLabels: $.values.common.ruleLabels },
      },

      prometheus+: {
        replicas: 1,
        externalLabels: {
          cluster: std.extVar('cluster_name'),
        },
      },

      alertmanager+: {
        replicas: 1,
      },

      grafana+: {
        dashboards+: $.gitpod.mixin.grafanaDashboards,
      },

    },

    gitpod: gitpod($.values.gitpodParams),
    alertmanager+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet'),
    },
    kubeStateMetrics+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet'),
    },
    kubernetesControlPlane+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet'),
    },
    nodeExporter+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet'),
    },
    prometheus+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet'),
    },
    prometheusOperator+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet'),
    },
    kubePrometheus+: {
      namespace+: {
        metadata+: {
          labels+: {
            namespace: std.extVar('namespace'),
          },
        },
      },
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet'),
    },
  }
;
[
  kp.kubePrometheus.namespace,
  kp.restrictedPodSecurityPolicy,
] +
[kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics)]
