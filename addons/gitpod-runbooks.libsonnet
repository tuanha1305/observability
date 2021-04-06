local k8sUtils = (import 'github.com/kubernetes-monitoring/kubernetes-mixin/lib/utils.libsonnet');

local addRunbookURL(rule) = rule {
  [if 'alert' in rule then 'annotations']+: {
    runbook_url: 'https://www.github.com/gitpod-io/runbooks/%s' % rule.alert + '.md',
  },
};

{
  prometheus+: {
    prometheusRule+: {
      spec+:
        k8sUtils.mapRuleGroups(addRunbookURL),
    },
  },
  alertmanager+: {
    prometheusRule+: {
      spec+:
        k8sUtils.mapRuleGroups(addRunbookURL),
    },
  },
  kubeStateMetrics+: {
    prometheusRule+: {
      spec+:
        k8sUtils.mapRuleGroups(addRunbookURL),
    },
  },
  kubernetesControlPlane+: {
    prometheusRule+: {
      spec+:
        k8sUtils.mapRuleGroups(addRunbookURL),
    },
  },
  nodeExporter+: {
    prometheusRule+: {
      spec+:
        k8sUtils.mapRuleGroups(addRunbookURL),
    },
  },
  prometheusOperator+: {
    prometheusRule+: {
      spec+:
        k8sUtils.mapRuleGroups(addRunbookURL),
    },
  },
}
