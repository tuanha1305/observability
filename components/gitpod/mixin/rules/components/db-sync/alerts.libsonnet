{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'gitpod-component-db-sync-alerts',
        rules: [
          {
            alert: 'GitpodDBSyncSynchronizationFallingBehind',
            'for': '10m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              runbook_url: 'https://www.notion.so/gitpod/GitpodDBSyncSynchronizationFallingBehind',
              summary: 'DB-Sync synchronization cycles are falling behind.',
              description: '95% of db-sync synchronizations are taking longer than the configured cycle period for more than 10m.',
            },
            expr: 'gitpod_db_sync_cycle_duration_seconds:95th_percentile > gitpod_db_sync_configured_sync_interval_info',
          },
          {
            alert: 'GitpodDBSyncSynchronizationFallingBehind',
            'for': '10m',
            labels: {
              severity: 'critical',
            },
            annotations: {
              runbook_url: 'https://www.notion.so/gitpod/GitpodDBSyncSynchronizationFallingBehind',
              summary: 'DB-Sync synchronization cycles are falling behind.',
              description: '50% of db-sync synchronizations are taking longer than the configured cycle period for more than 10m.',
            },
            expr: 'gitpod_db_sync_cycle_duration_seconds:50th_percentile > gitpod_db_sync_configured_sync_interval_info',
          },
        ],
      },
    ],
  },
}
