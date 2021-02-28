local nodeExporter = import './node-exporter.libsonnet';
local kubeStateMetrics = import './kube-state-metrics.libsonnet';
local prometheusOperator = import './prometheus-operator.libsonnet';
local prometheus = import './prometheus.libsonnet';
local alertmanager = import './alertmanager.libsonnet';
local grafana = import './grafana.libsonnet';
local kubernetes = import './kubernetes.libsonnet';

// Configuration shared between all components of the stack
local defaults = {

    clusterName: std.extVar('cluster_name'),
    namespace: std.extVar('namespace'),
    prometheusName: 'prometheus-' + $.namespace,
    alertmanagerName: 'alertmanager-' + $.namespace,
    ruleLabels: {
        role: 'alert-rules',
        prometheus: $.prometheusName
    },

    remoteWriteUrl: std.extVar('remote_write_url'),

    // Used to override default version comming from upstream
    versions: {
        nodeExporter: '1.1.1',
        kubeStateMetrics: '1.9.7',
        prometheusOperator: '0.46.0',
        prometheus: '2.25.0',
        alertmanager: '0.21.0',
        grafana: '7.4.3',
    },

    // Used to override default images comming from upstream
    images: {
        nodeExporter: 'quay.io/prometheus/node-exporter:v' + $.versions['nodeExporter'],
        kubeStateMetrics: 'quay.io/coreos/kube-state-metrics:v' + $.versions['kubeStateMetrics'],
        prometheusOperator: 'quay.io/prometheus-operator/prometheus-operator:v' + $.versions['prometheusOperator'],
        prometheusOperatorReloader: 'quay.io/prometheus-operator/prometheus-config-reloader:v' + $.versions['prometheusOperator'],
        prometheus: 'quay.io/prometheus/prometheus:v' + $.versions['prometheus'],
        alertmanager: 'quay.io/prometheus/alertmanager:v' + $.versions['alertmanager'],
        grafana: 'grafana/grafana:v' + $.versions['grafana'],
    },

    // Labels to be applied on every component of the stack
    commonLabels: {
        // empty for now
    },
};

local manifests = {
    values+:: {
        default: defaults,

        // Configuration of all components
        nodeExporter: {
            namespace: $.values.default.namespace,
            version: $.values.default.versions['nodeExporter'],
            image: $.values.default.images['nodeExporter'],
            commonLabels+: $.values.default.commonLabels,
            mixin+: {
                ruleLabels: $.values.default.ruleLabels,
            },
        },

        kubeStateMetrics: {
            namespace: $.values.default.namespace,
            version: $.values.default.versions['kubeStateMetrics'],
            image: $.values.default.images['kubeStateMetrics'],
            commonLabels+: $.values.default.commonLabels,
            mixin+: {
                ruleLabels: $.values.default.ruleLabels,
            },
        },

        prometheusOperator: {
            namespace: $.values.default.namespace,
            version: $.values.default.versions['prometheusOperator'],
            image: $.values.default.images['prometheusOperator'],
            configReloaderImage: $.values.default.images['prometheusOperatorReloader'],
            commonLabels+: $.values.default.commonLabels,
            mixin+: {
                ruleLabels: $.values.default.ruleLabels,
            },
        },

        alertmanager: {
            name: $.values.default.alertmanagerName,
            namespace: $.values.default.namespace,
            version: $.values.default.versions['alertmanager'],
            image: $.values.default.images['alertmanager'],
            replicas: 1,
            commonLabels+: $.values.default.commonLabels,
            mixin+: { 
                ruleLabels: $.values.default.ruleLabels, 
            },
        },
        
        prometheus: {
            name: $.values.default.prometheusName,
            namespace: $.values.default.namespace,
            version: $.values.default.versions['prometheus'],
            image: $.values.default.images['prometheus'],
            replicas: 1,
            commonLabels+: $.values.default.commonLabels,
            alertmanagerName: $.values.alertmanager.name,
            clusterName: $.values.default.clusterName,
            remoteWriteUrl: $.values.default.remoteWriteUrl,
            // TODO(arthursens): verify where this 'namespaces' field below is used for.
            namespaces+: [],
            mixin+: {
                ruleLabels: $.values.default.ruleLabels,
            },
        },

        grafana: {
            namespace: $.values.default.namespace,
            version: $.values.default.versions['grafana'],
            image: $.values.default.images['grafana'],
            commonLabels+: $.values.default.commonLabels,
            prometheusName: $.values.default.prometheusName,
            local allDashboards = $.nodeExporter.mixin.grafanaDashboards + $.prometheus.mixin.grafanaDashboards + $.kubernetes.mixin.grafanaDashboards,
            // Allow-listing dashboards that are going into the product. List needs to be sorted for std.setMember to work
            local includeDashboards = [
                'apiserver.json',
                'cluster-total.json',
                'controller-manager.json',
                'etcd.json',
                'k8s-resources-cluster.json',
                'k8s-resources-namespace.json',
                'k8s-resources-node.json',
                'k8s-resources-pod.json',
                'k8s-resources-workload.json',
                'k8s-resources-workloads-namespace.json',
                'kubelet.json',
                'namespace-by-pod.json',
                'namespace-by-workload.json',
                'node-cluster-rsrc-use.json',
                'node-rsrc-use.json',
                'nodes.json',
                'persistentvolumesusage.json',
                'pod-total.json',
                'prometheus.json',
                'prometheus-remote-write.json',
                'proxy.json',
                'scheduler.json',
                'statefulset.json',
                'workload-total.json',
            ],
            dashboards: {
                [k]: allDashboards[k] for k in std.objectFields(allDashboards)
                // if std.setMember(k, includeDashboards)
            },
            datasources: [{
                name: $.values.default.prometheusName,
                type: 'prometheus',
                access: 'proxy',
                orgId: 1,
                url: 'http://' + $.values.default.prometheusName + '.' + $.values.default.namespace + '.svc:9090',
                version: 1,
                editable: false,
            }],
        },




        kubernetes: {
            namespace: 'kube-system',
            prometheusNamespace: $.values.default.namespace,
            commonLabels+: $.values.default.commonLabels,
            mixin+: {
                ruleLabels: $.values.default.ruleLabels,
            },
        },
    },   


    // Object creation
    nodeExporter: nodeExporter($.values.nodeExporter),
    kubeStateMetrics: kubeStateMetrics($.values.kubeStateMetrics),
    prometheusOperator: prometheusOperator($.values.prometheusOperator),
    prometheus: prometheus($.values.prometheus),
    alertmanager: alertmanager($.values.alertmanager),
    grafana: grafana($.values.grafana),

    kubernetes: kubernetes($.values.kubernetes),
    namespace: {
        apiVersion: 'v1',
        kind: 'Namespace',
        metadata: {
            name: $.values.default.namespace,
      },
    },
};

// Creation of YAML manifests
{ 'namespace': manifests.namespace} +
{ ['prometheus/' + name]: manifests.prometheus[name] for name in std.objectFields(manifests.prometheus) } +

// Preview environments are only interested on monitoring gitpod itself.
// There is no need to include anything more than a namespace and prometheus instance for them.
if !std.extVar('is_preview_env') then
  { ['grafana/' + name]: manifests.grafana[name] for name in std.objectFields(manifests.grafana) } +
  { ['kubernetes/' + name]: manifests.kubernetes[name] for name in std.objectFields(manifests.kubernetes) } +
  { ['prometheus-operator/' + name]: manifests.prometheusOperator[name] for name in std.objectFields(manifests.prometheusOperator) } +
  { ['kube-state-metrics/' + name]: manifests.kubeStateMetrics[name] for name in std.objectFields(manifests.kubeStateMetrics) } +
  { ['node-exporter/' + name]: manifests.nodeExporter[name] for name in std.objectFields(manifests.nodeExporter) } +
  { ['alertmanager/' + name]: manifests.alertmanager[name] for name in std.objectFields(manifests.alertmanager) }
else 
  {}