local gitpod = import './components/gitpod/gitpod.libsonnet';

local externalVars = {
  // Provided via jsonnet CLI
  namespace: std.extVar('namespace'),
};

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/platforms/gke.libsonnet') +
  //   (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
  (import './addons/disable-grafana-auth.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: externalVars.namespace,
      },
      grafana+: {
        dashboards+: $.gitpod.mixin.grafanaDashboards,
      },
    },
  }
;

// LTS grafana's will always be the ones we want to provide an external DNS to.
local manifests = kp + (import './addons/grafana-on-gcp-oauth.libsonnet');

{ namespace: manifests.kubePrometheus.namespace } +
// { 'podsecuritypolicy-restricted': manifests.restrictedPodSecurityPolicy } +
{ ['grafana/' + name]: manifests.grafana[name] for name in std.objectFields(manifests.grafana) }
