{
  prometheusRules+:: {
    groups+: [
      {
        name: 'gitpod-login-slo-records',
        rules: [
          {
            record: 'gitpod_agent_smith_policed_workspaces:5m_saturation_ratio',
            expr: |||
              sum(rate(gitpod_agent_smith_discovered_workspaces_total[5m]))
              /
              sum(rate(gitpod_agent_smith_policed_workspaces_total[5m]))
            |||,
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:30m_saturation_ratio',
            expr: |||
              sum(rate(gitpod_agent_smith_discovered_workspaces_total[30m]))
              /
              sum(rate(gitpod_agent_smith_policed_workspaces_total[30m]))
            |||,
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:1h_saturation_ratio',
            expr: |||
              sum(rate(gitpod_agent_smith_discovered_workspaces_total[1h]))
              /
              sum(rate(gitpod_agent_smith_policed_workspaces_total[1h]))
            |||,
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:2h_saturation_ratio',
            expr: |||
              sum(rate(gitpod_agent_smith_discovered_workspaces_total[2h]))
              /
              sum(rate(gitpod_agent_smith_policed_workspaces_total[2h]))
            |||,
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:6h_saturation_ratio',
            expr: |||
              sum(rate(gitpod_agent_smith_discovered_workspaces_total[6h]))
              /
              sum(rate(gitpod_agent_smith_policed_workspaces_total[6h]))
            |||,
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:1d_saturation_ratio',
            expr: |||
              sum(rate(gitpod_agent_smith_discovered_workspaces_total[1d]))
              /
              sum(rate(gitpod_agent_smith_policed_workspaces_total[1d]))
            |||,
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:30d_saturation_ratio',
            expr: |||
              sum(rate(gitpod_agent_smith_discovered_workspaces_total[30d]))
              /
              sum(rate(gitpod_agent_smith_policed_workspaces_total[30d]))
            |||,
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:slo_target',
            expr: 0.95,
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:error_budget_remaining',
            expr: 'gitpod_agent_smith_policed_workspaces:monthly_availability - gitpod_agent_smith_policed_workspaces:slo_target',
          },
          {
            record: 'gitpod_agent_smith_policed_workspaces:monthly_availability',
            expr: '1 - apiagent_smith_request_total:30d_failure_ratio',
          },
        ],
      },
    ],
  },
}
