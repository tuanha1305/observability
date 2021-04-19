local gitpod = import '../components/gitpod/gitpod.libsonnet';

local kp =
  (import '../vendor/kube-prometheus/main.libsonnet') +
  (import '../vendor/kube-prometheus/platforms/gke.libsonnet') +
  (import '../vendor/kube-prometheus/addons/podsecuritypolicies.libsonnet') +
  (import '../addons/disable-grafana-auth.libsonnet') +
  (import '../vendor/kube-prometheus/addons/strip-limits.libsonnet') +
  (import '../addons/gitpod-runbooks.libsonnet') +
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
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet'),
    },
    kubeStateMetrics+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet'),
    },
    kubernetesControlPlane+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet'),
    },
    nodeExporter+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet'),
    },
    prometheus+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet'),
    },
    prometheusOperator+: {
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet'),
    },
    kubePrometheus+: {
      namespace+: {
        metadata+: {
          labels+: {
            namespace: std.extVar('namespace'),
          },
        },
      },
      prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet'),
    },
  }
;

local manifests = kp +
                  (if std.extVar('remote_write_url') != '' then (import '../addons/remote-write.libsonnet') else {}) +
                  (if std.extVar('slack_webhook_url_critical') != '' then (import '../addons/slack-alerting.libsonnet') else {}) +
                  (if std.extVar('dns_name') != '' then (import '../addons/grafana-on-gcp-oauth.libsonnet') else {})
;

{ namespace: manifests.kubePrometheus.namespace } +
{ 'podsecuritypolicy-restricted': manifests.restrictedPodSecurityPolicy } +
{ ['grafana/' + name]: manifests.grafana[name] for name in std.objectFields(manifests.grafana) } +
{ ['prometheus/' + name]: manifests.prometheus[name] for name in std.objectFields(manifests.prometheus) } +
{ ['gitpod/' + name]: manifests.gitpod[name] for name in std.objectFields(manifests.gitpod) } +
// Generic alerting rules, not related to a specific exporter.
{ 'prometheus/kube-prometheus-prometheusRule': manifests.kubePrometheus.prometheusRule }
