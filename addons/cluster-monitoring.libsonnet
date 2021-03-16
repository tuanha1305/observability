// The cluster-monitoring addon provides json snippets that are specific for installations responsible for full cluster monitoring.

{

} +
// Grafanas deployed on the monitored clusters shouldn't need a DNS.
// For playground purposes, this can be optionally enabled.
(if std.extVar('dns_name') != '' then import './grafana-on-gcp-oauth.libsonnet')
