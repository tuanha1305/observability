{
  prometheusRules+:: {
    groups+: [
      {
        name: 'gitpod-component-db-sync-records',
        rules: [
          {
            record: 'gitpod_db_sync_cycle_duration_seconds:99th_percentile',
            expr: 'histogram_quantile(0.99, sum(rate(gitpod_db_sync_cycle_duration_seconds_bucket[5m])) by (le))',
          },
          {
            record: 'gitpod_db_sync_cycle_duration_seconds:95th_percentile',
            expr: 'histogram_quantile(0.95, sum(rate(gitpod_db_sync_cycle_duration_seconds_bucket[5m])) by (le))',
          },
          {
            record: 'gitpod_db_sync_cycle_duration_seconds:50th_percentile',
            expr: 'histogram_quantile(0.50, sum(rate(gitpod_db_sync_cycle_duration_seconds_bucket[5m])) by (le))',
          },
          {
            record: 'gitpod_db_sync_cycle_duration_seconds:avg',
            expr: |||
              sum(rate(gitpod_db_sync_cycle_duration_seconds_sum[5m]))
              /
              sum(rate(gitpod_db_sync_cycle_duration_seconds_count[5m]))
            |||,
          },
        ],
      },
    ],
  },
}
