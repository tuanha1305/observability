// Before mapping and changing alerts severity, it is good to keep track on ho they are being categorized upstream!
// There is probably a good reason for why they are categorized the way they are.
local alertSeverityMap = {
  // WIP Page alerts
  // Alerts with 'Page' severity will be routed to PagerDuty instead of Slack.
  // We have a really restricted page severity because not all 'critical' alerts are actionable today. 
  // The final goal is that 'critical' only contain actionable alerts and they will be the ones routed to pagerduty.
  // When we have that, then let's remove the 'page' severity.
  NodeFilesystemAlmostOutOfSpace: 'page',

  // Critical alerts
  // Map alerts as 'critical' if it indicates a problem that requires human intervention immediately.
  KubePodCrashLooping: 'critical',

  // Warning alerts
  // Map alerts as 'warning' if it indicates a problem that needs human intervention, but it can wait until the next shift.
  KubeStateMetricsListErrors: 'warning',

  // Info alerts
  // Map alerts as 'warning' if there is no need for human intervention at all, but it still provides useful information about the system behavior.
  Watchdog: 'info',
};

{
  spec+: {
    groups: std.map(
      function(group) group {
        rules: std.map(
          function(rule)
            if 'alert' in rule && (rule.alert in alertSeverityMap) then
              rule { labels+: { severity: alertSeverityMap[rule.alert] } }
            else
              rule,
          super.rules
        ),
      },
      super.groups
    ),
  },
}
