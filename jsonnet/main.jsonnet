local nodeExporter = import './node-exporter.libsonnet';

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
        nodeExporter: '1.0.1',
    },

    // Used to override default images comming from upstream
    images: {
        nodeExporter: 'quay.io/prometheus/node-exporter:v' + $.versions['nodeExporter'],
    },

    // Labels to be applied on every component of the stack
    commonLabels: {
        
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
    },

    // Object creation
    nodeExporter: nodeExporter($.values.nodeExporter),
};

// Creation of YAML manifests
{ ['node-exporter/' + name]: inCluster.nodeExporter[name] for name in std.objectFields(inCluster.nodeExporter) }