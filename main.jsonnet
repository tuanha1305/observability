local gitpod = import './components/gitpod/gitpod.libsonnet';

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/platforms/gke.libsonnet') +
  (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
  (import './addons/disable-grafana-auth.libsonnet') +
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
;

local manifests = kp +
                  (if std.extVar('remote_write_url') != '' then (import './addons/remote-write.libsonnet') else {}) +
                  (if std.extVar('slack_webhook_url') != '' then (import './addons/slack-alerting.libsonnet') else {}) +
                  (if std.extVar('dns_name') != '' then (import './addons/grafana-on-gcp-oauth.libsonnet') else {}) +
                  (if std.extVar('is_preview_env') then (import './addons/preview-env.libsonnet') else (import './addons/cluster-monitoring.libsonnet'))
;

{ namespace: manifests.kubePrometheus.namespace } +
{ 'podsecuritypolicy-restricted': manifests.restrictedPodSecurityPolicy } +
{ ['grafana/' + name]: manifests.grafana[name] for name in std.objectFields(manifests.grafana) } +
{ ['prometheus/' + name]: manifests.prometheus[name] for name in std.objectFields(manifests.prometheus) } +
{ ['gitpod/' + name]: manifests.gitpod[name] for name in std.objectFields(manifests.gitpod) } +
// Generic alerting rules, not related to a specific exporter.
{ 'prometheus/kube-prometheus-prometheusRule': manifests.kubePrometheus.prometheusRule } +

// Preview environments are only interested on monitoring gitpod itself.
// There is no need to include anything more than a namespace and prometheus+grafana for them.
if !std.extVar('is_preview_env') then
  { ['alertmanager/' + name]: manifests.alertmanager[name] for name in std.objectFields(manifests.alertmanager) } +
  // BlackboxExporter Can be used for certificates and uptimecheck monitoring, but not necessary for now.
  // { ['blackbox-exporter/' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
  { ['kube-state-metrics/' + name]: manifests.kubeStateMetrics[name] for name in std.objectFields(manifests.kubeStateMetrics) } +
  { ['kubernetes/' + name]: manifests.kubernetesControlPlane[name] for name in std.objectFields(manifests.kubernetesControlPlane) }
  { ['node-exporter/' + name]: manifests.nodeExporter[name] for name in std.objectFields(manifests.nodeExporter) } +
  // Prometheus adapter replaces k8s metrics-server. GKE enables metrics-server by default and we're not interested in replacing it.
  // { ['prometheus-adapter/' + name]: manifests.prometheusAdapter[name] for name in std.objectFields(manifests.prometheusAdapter) } +
  { ['prometheus-operator/' + name]: manifests.prometheusOperator[name] for name in std.objectFields(manifests.prometheusOperator) }
else
  {}
