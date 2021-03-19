local gitpod = import './components/gitpod/gitpod.libsonnet';

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/platforms/gke.libsonnet') +
  (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
  (import './addons/disable-grafana-auth.libsonnet') +
  // LTS grafana's will always be the ones we want to provide an external DNS to.
  (import './addons/grafana-on-gcp-oauth.libsonnet')
  {
    values+:: {
      common+: {
        namespace: 'monitoring-central',
      },
      gitpodParams: {
        namespace: std.extVar('namespace'),
      },
      grafana+: {
        dashboards+: $.gitpod.mixin.grafanaDashboards,
        datasources: [{
          name: 'Metrics Long Term Storage',
          type: 'prometheus',
          access: 'proxy',
          orgId: 1,
          url: 'http://victoriametrics.' + $.values.common.namespace + '.svc:8428',
          version: 1,
          editable: false,
        }],
      },
    },

    // Included just to generate gitpod dashboards. No need to generate any YAML.
    gitpod: gitpod($.values.gitpodParams),

    grafana+: {
      // Disabling serviceMonitor for monitoring-central since there is no prometheus running there.
      serviceMonitor:: {},
    },
  }
;

local manifests = kp;

{ namespace: manifests.kubePrometheus.namespace } +
{ 'podsecuritypolicy-restricted': manifests.restrictedPodSecurityPolicy } +
{ ['grafana/' + name]: manifests.grafana[name] for name in std.objectFields(manifests.grafana) }
