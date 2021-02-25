local nodeExporter = import './node-exporter.libsonnet';
local kubeStateMetrics = import './kube-state-metrics.libsonnet';
local prometheusOperator = import './prometheus-operator.libsonnet';
local prometheus = import './prometheus.libsonnet';
local alertmanager = import './alertmanager.libsonnet';

// Configuration shared between all components of the stack
local commonConfig = {
    namespace: std.extVar('namespace'),
    prometheusName: 'prometheus-' + $.namespace,
    alertmanagerName: 'alertmanager-' + $.namespace,
    ruleLabels: {
        role: 'alert-rules',
        prometheus: $.prometheusName
    },

    // Used to override default version comming from upstream
    versions: {
        nodeExporter: '1.1.1',
        kubeStateMetrics: '1.9.7',
        prometheusOperator: '0.46.0',
        prometheus: '2.25.0',
        alertmanager: '0.21.0',
    },

    // Used to override default images comming from upstream
    images: {
        nodeExporter: 'quay.io/prometheus/node-exporter:v' + $.versions['nodeExporter'],
        kubeStateMetrics: 'quay.io/coreos/kube-state-metrics:v' + $.versions['kubeStateMetrics'],
        prometheusOperator: 'quay.io/prometheus-operator/prometheus-operator:v' + $.versions['prometheusOperator'],
        prometheusOperatorReloader: 'quay.io/prometheus-operator/prometheus-config-reloader:v' + $.versions['prometheusOperator'],
        prometheus: 'quay.io/prometheus/prometheus:v' + $.versions['prometheus'],
        alertmanager: 'quay.io/prometheus/alertmanager:v' + $.versions['alertmanager'],
    },

    // Labels to be applied on every component of the stack
    commonLabels: {
        // empty for now
    },
};

local inCluster = {
    values+:: {
        common: commonConfig,

        // Configuration of all components
        nodeExporter: {
            namespace: $.values.common.namespace,
            version: $.values.common.versions['nodeExporter'],
            image: $.values.common.images['nodeExporter'],
            commonLabels+: $.values.common.commonLabels,
            mixin+: {
                ruleLabels: $.values.common.ruleLabels,
                //_config+: {
                //    diskDeviceSelector: 'device=~"sd.+"',
                //},
            },
        },

        kubeStateMetrics: {
            namespace: $.values.common.namespace,
            version: $.values.common.versions['kubeStateMetrics'],
            image: $.values.common.images['kubeStateMetrics'],
            commonLabels+: $.values.common.commonLabels,
            mixin+: {
                ruleLabels: $.values.common.ruleLabels,
                //_config+: {
                //    diskDeviceSelector: 'device=~"sd.+"',
                //},
            },
        },

        prometheusOperator: {
            namespace: $.values.common.namespace,
            version: $.values.common.versions['prometheusOperator'],
            image: $.values.common.images['prometheusOperator'],
            configReloaderImage: $.values.common.images['prometheusOperatorReloader'],
            commonLabels+: $.values.common.commonLabels,
            mixin+: {
                ruleLabels: $.values.common.ruleLabels,
                _config+: {
                    //prometheusSelector: 'job=~"prometheus-k8s|prometheus-user-workload"',
                },
            },
        },

        alertmanager: {
            name: $.values.common.alertmanagerName,
            namespace: $.values.common.namespace,
            version: $.values.common.versions['alertmanager'],
            image: $.values.common.images['alertmanager'],
            replicas: 1,
            commonLabels+: $.values.common.commonLabels,
            mixin+: { 
                ruleLabels: $.values.common.ruleLabels, 
            },
        },
        
        prometheus: {
            name: $.values.common.prometheusName,
            namespace: $.values.common.namespace,
            version: $.values.common.versions['prometheus'],
            image: $.values.common.images['prometheus'],
            replicas: 1,
            commonLabels+: $.values.common.commonLabels,
            alertmanagerName: $.values.alertmanager.name,
            namespaces+: [],
            mixin+: {
                ruleLabels: $.values.common.ruleLabels,
                _config+: {
                },
            },
        },
    },   


    // Object creation
    nodeExporter: nodeExporter($.values.nodeExporter),
    kubeStateMetrics: kubeStateMetrics($.values.kubeStateMetrics),
    prometheusOperator: prometheusOperator($.values.prometheusOperator),
    prometheus: prometheus($.values.prometheus),
    alertmanager: alertmanager($.values.alertmanager),

    namespace: {
        apiVersion: 'v1',
        kind: 'Namespace',
        metadata: {
            name: $.values.common.namespace,
      },
    },
};

// Creation of YAML manifests
{ 'namespace': inCluster.namespace} +
{ ['node-exporter/' + name]: inCluster.nodeExporter[name] for name in std.objectFields(inCluster.nodeExporter) } +
{ ['kube-state-metrics/' + name]: inCluster.kubeStateMetrics[name] for name in std.objectFields(inCluster.kubeStateMetrics) } +
{ ['prometheus-operator/' + name]: inCluster.prometheusOperator[name] for name in std.objectFields(inCluster.prometheusOperator) } +
{ ['prometheus/' + name]: inCluster.prometheus[name] for name in std.objectFields(inCluster.prometheus) } +

// Optionally include Alertmanager
// There is no need to exclude alerting rules if they are not routed anywhere
if std.extVar('include_alerting') then
  { ['alertmanager/' + name]: inCluster.alertmanager[name] for name in std.objectFields(inCluster.alertmanager) }
else 
  {}