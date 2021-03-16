local externalVars = {
  // Provided via jsonnet CLI
  clusterName: std.extVar('cluster_name'),
  namespace: std.extVar('namespace'),
  remoteWriteUrl: std.extVar('remote_write_url'),
  slackWebhookUrl: std.extVar('slack_webhook_url'),
  slackChannel: std.extVar('slack_channel'),
  isPreviewEnv: std.extVar('is_preview_env'),
};

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/platforms/gke.libsonnet') +
  //   (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: externalVars.namespace,
      },
    },
  } +
  // Scaling down to 1 replica
  {
    prometheus+: {
      prometheus+: {
        spec+: {
          externalLabels: {
            cluster: externalVars.clusterName,
          },
          replicas: 1,
        },
      },
    },

    alertmanager+: {
      alertmanager+: {
        spec+: {
          replicas: 1,
        },
      },
    },
  }
;

local manifests = kp +
                  (if externalVars.remoteWriteUrl != '' then (import './addons/remote-write.libsonnet') else {}) +
                  (if externalVars.slackWebhookUrl != '' then (import './addons/slack-alerting.libsonnet') else {}) +
                  (if externalVars.isPreviewEnv then (import './addons/preview-env.libsonnet') else (import './addons/cluster-monitoring.libsonnet'))
;

{ namespace: manifests.kubePrometheus.namespace } +
// { 'podsecuritypolicy-restricted': manifests.restrictedPodSecurityPolicy } +
{ ['grafana/' + name]: manifests.grafana[name] for name in std.objectFields(manifests.grafana) } +
{ ['prometheus/' + name]: manifests.prometheus[name] for name in std.objectFields(manifests.prometheus) } +
// Generic alerting rules, not related to a specific exporter.
{ 'prometheus/kube-prometheus-prometheusRule': manifests.kubePrometheus.prometheusRule } +

// Preview environments are only interested on monitoring gitpod itself.
// There is no need to include anything more than a namespace and prometheus instance for them.
if !externalVars.isPreviewEnv then
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
