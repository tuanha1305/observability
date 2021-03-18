{
  values+:: {
    alertmanager+: {
      config: |||
        global:
          resolve_timeout: 5m
        route:
          receiver: Black_Hole
          group_by:
          - alertname
          routes:
          - receiver: Watchdog
            match:
              alertname: Watchdog
          - receiver: Slack
            match:
              severity: critical
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 6h
        inhibit_rules:
        - source_match:
            severity: critical
          target_match_re:
            severity: warning|info
          equal:
          - alertname
        - source_match:
            severity: warning
          target_match_re:
            severity: info
          equal:
          - alertname
        receivers:
        - name: Black_Hole
        - name: Watchdog
        - name: Slack
          slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrl)s
            channel: '%(slackChannel)s'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] %(clusterName)s Cluster Alerting'
            text: |
              {{ range .Alerts }}
              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
        templates: []
      ||| % {
        clusterName: std.extVar('cluster_name'),
        slackWebhookUrl: std.extVar('slack_webhook_url'),
        slackChannel: std.extVar('slack_channel'),
      },
    },
  },
}
