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
          - receiver: PagerDuty
            match:
              severity: page
          - receiver: SlackCritical
            match:
              severity: critical
          - receiver: SlackWarning
            match:
              severity: warning
          - receiver: SlackInfo
            match:
              severity: info
          - receiver: Watchdog
            match:
              alertname: Watchdog
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
        - name: SlackCritical
          slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlCritical)s
            channel: '%(slackChannelPrefix)s_critical'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **Immediate Action Required!**

              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
        - name: SlackWarning
          slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlWarning)s
            channel: '%(slackChannelPrefix)s_warning'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **Please take a look when possible**

              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
        - name: SlackInfo
          slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlInfo)s
            channel: '%(slackChannelPrefix)s_info'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **No need for human intervention :slightly_smiling_face:

              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
        - name: PagerDuty
          pagerduty_configs:
          - send_resolved: true
            routing_key: '%(pagerdutyRoutingKey)s'
            description: '{{ .Annotations.description }}'
            links:
              - href: '{{ .CommonAnnotations.runbook_url }}'
                text: 'Runbook'
        templates: []
      ||| % {
        clusterName: std.extVar('cluster_name'),
        slackWebhookUrlCritical: std.extVar('slack_webhook_url_critical'),
        slackWebhookUrlWarning: std.extVar('slack_webhook_url_warning'),
        slackWebhookUrlInfo: std.extVar('slack_webhook_url_info'),
        slackChannelPrefix: std.extVar('slack_channel_prefix'),
        pagerdutyRoutingKey: std.extVar('pagerduty_routing_key'),
      },
    },
  },
}
