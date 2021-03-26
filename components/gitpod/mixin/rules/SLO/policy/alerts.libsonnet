{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'gitpod-policy-slo-alerts',
        rules: [
          // Please read this entire page: https://sre.google/workbook/alerting-on-slos/
          // We are alerting on strategy #6
          {
            alert: 'GitpodAgentSmithPolicySaturationBudgetBurn',
            labels: {
              severity: 'critical',
            },
            annotations: {
              runbook_url: 'https://www.notion.so/gitpod/GitpodAgentSmithPolicySaturationBudgetBurn',
              summary: 'Error budget is being burn too quickly.',
              description: 'Error budget is being burn too quickly. At this rate, the whole monthly budget will be burnt in less than 2 days.',
            },
            expr: |||
              (
                gitpod_agent_smith_policed_workspaces:1h_saturation_ratio > (14.4 * (1 - gitpod_server_login_requests_total:slo_target))
                and
                gitpod_agent_smith_policed_workspaces:5m_saturation_ratio > (14.4 * (1 - gitpod_server_login_requests_total:slo_target))
              )
              or
              (
                gitpod_agent_smith_policed_workspaces:6h_saturation_ratio > (6 * (1 - gitpod_server_login_requests_total:slo_target))
                and
                gitpod_agent_smith_policed_workspaces:30m_saturation_ratio > (6 * (1 - gitpod_server_login_requests_total:slo_target))
              )
            |||,
          },
          {
            alert: 'GitpodAgentSmithPolicySaturationBudgetBurn',
            labels: {
              severity: 'warning',
            },
            annotations: {
              runbook_url: 'https://www.notion.so/gitpod/GitpodAgentSmithPolicySaturationBudgetBurn',
              summary: 'Error budget is being burn quickly.',
              description: 'Error budget is being burn quickly. At this rate, the whole monthly budget will be burnt in less than 10 days.',
            },
            expr: |||
              (
                gitpod_agent_smith_policed_workspaces:1d_saturation_ratio > (3 * (1 - gitpod_server_login_requests_total:slo_target))
                and
                gitpod_agent_smith_policed_workspaces:2h_saturation_ratio > (3 * (1 - gitpod_server_login_requests_total:slo_target))
              )
              or
              (
                gitpod_agent_smith_policed_workspaces:3d_saturation_ratio > (1 * (1 - gitpod_server_login_requests_total:slo_target))
                and
                gitpod_agent_smith_policed_workspaces:6h_saturation_ratio > (1 * (1 - gitpod_server_login_requests_total:slo_target))
              )
            |||,
          },
        ],
      },
    ],
  },
}
