local nodeExporter = import './node-exporter.libsonnet';
local kubeStateMetrics = import './kube-state-metrics.libsonnet';

// Configuration shared between all components of the stack
local commonConfig = {
    namespace: std.extVar('namespace'),
    prometheusName: 'prometheus-' + $.namespace,
    ruleLabels: {
        role: 'alert-rules',
        prometheus: $.prometheusName
    },

    // Used to override default version comming from upstream
    versions: {
        prometheus: '2.25.0',
        nodeExporter: '1.1.1',
        kubeStateMetrics: '1.9.7',
    },

    // Used to override default images comming from upstream
    images: {
        nodeExporter: 'quay.io/prometheus/node-exporter:v' + $.versions['nodeExporter'],
        kubeStateMetrics: 'quay.io/coreos/kube-state-metrics:v' + $.versions['kubeStateMetrics'],
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
    },

    // Object creation
    nodeExporter: nodeExporter($.values.nodeExporter),
    kubeStateMetrics: kubeStateMetrics($.values.kubeStateMetrics),
};

// Creation of YAML manifests
{ ['node-exporter/' + name]: inCluster.nodeExporter[name] for name in std.objectFields(inCluster.nodeExporter) } +
{ ['kube-state-metrics/' + name]: inCluster.kubeStateMetrics[name] for name in std.objectFields(inCluster.kubeStateMetrics) }