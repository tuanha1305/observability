/**
 * Creates a set of YAML files necessary to deploy an Alertmanager instance ontop Kubernetes
 * This lib is meant to work as a workaround for https://github.com/prometheus-operator/prometheus-operator/issues/3737
 * Once the AlertmanagerConfig is able to route alerts from several namespaces this library should be deleted in
 * favor of alertmanager.libsonnet, alongside any fixes that needs to be done in said library.
 *
 * @param namespace(Required) The namespace where the Alertmanager resources will be deployed to.
 * @param version(Required) The version of the alertmanager that will be deployed.
 * @param image(Required) The Prometheus image used to deploy Prometheus.
 * @param replicas(Required) The amount of Alertmanager replicas.
 * @param slack_webhook_url(Required) The webhook URL of the Slack workspace where alerts will be sent to.
 * @param channel(Required) The slack channel where critical alerts will be routed to.
 * @param config(Optional) The configuration used to manage alerts.
 *
 * @method aletmanager(params) Creates an alertmanager object.
 */

local defaults = {
  local defaults = self,

  name: error 'must provide name',
  namespace: error 'must provide namespace',
  version: error 'must provide version',
  image: error 'must provide image',
  replicas: error 'must provide replicas',
  slack_webhook_url: error 'must provide slack_webhook_url',
  channel: error 'must provide channel',

  commonLabels:: {
    'app.kubernetes.io/name': 'alertmanager',
    'app.kubernetes.io/version': defaults.version,
    'app.kubernetes.io/component': 'alert-router',
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },

  selectorLabels:: {
    [labelName]: defaults.commonLabels[labelName]
    for labelName in std.objectFields(defaults.commonLabels)
    if !std.setMember(labelName, ['app.kubernetes.io/version'])
  },

  config: {
    global: {
      resolve_timeout: '5m',
    },
    inhibit_rules: [{
      source_match: {
        severity: 'critical',
      },
      target_match_re: {
        severity: 'warning|info',
      },
      equal: ['alertname'],
    }, {
      source_match: {
        severity: 'warning',
      },
      target_match_re: {
        severity: 'info',
      },
      equal: ['alertname'],
    }],
    route: {
      group_by: ['namespace'],
      group_wait: '30s',
      group_interval: '5m',
      repeat_interval: '6h',
      receiver: 'Black_Hole',
      routes: [
        { receiver: 'DeadManSwitch', match: { alertname: 'DeadManSwitch' } },
        { receiver: 'Slack', match: { severity: 'critical' } },
      ],
    },
    receivers: [
      { name: 'Black_Hole' },
      { name: 'DeadManSwitch' },
      {
        name: 'Slack',
        slack_configs: [
          {
            send_resolved: true,
            api_url: defaults.slack_webhook_url,
            channel: defaults.channel,
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] Monitoring Event Notification',
            text: '{{ range .Alerts }}*Cluster:* {{ .Labels.cluster }}\n*Alert:* {{ .Annotations.summary }}\n*Description:* {{ .Annotations.description }}\n{{ end }}\n',
            actions: [
              {
                type: 'button',
                text: 'Runbook :book:',
                url: '{{ .CommonAnnotations.runbook_url }}',
              },
            ],
          },
        ],
      },
    ],
  },
};

function(params) {
  local cfg = defaults + params,

  mixin:: (import 'github.com/prometheus/alertmanager/doc/alertmanager-mixin/mixin.libsonnet') {
    _config+:: {
      alertmanagerName: cfg.name,
      alertmanagerSelector: 'job="' + cfg.name + '"',
    },
  },

  statefulSet: {
    apiVersion: 'apps/v1',
    kind: 'StatefulSet',
    metadata: {
      name: cfg.name,
      namespace: cfg.namespace,
      labels: { alertmanager: cfg.name } + cfg.commonLabels,
    },
    spec: {
      replicas: cfg.replicas,
      podManagementPolicy: 'Parallel',
      updateStrategy: {
        type: 'RollingUpdate',
      },
      selector: {
        matchLabels: cfg.selectorLabels,
      },
      serviceName: 'alertmanager-operated',
      template: {
        metadata: {
          labels: { alertmanager: cfg.name } + cfg.commonLabels,
        },
        spec: {
          containers: [
            {
              image: cfg.image,
              imagePullPolicy: 'IfNotPresent',
              name: 'alertmanager',
              env: [
                {
                  name: 'POD_IP',
                  valueFrom: {
                    fieldRef: {
                      apiVersion: 'v1',
                      fieldPath: 'status.podIP',
                    },
                  },
                },
              ],
              args: [
                '--config.file=/etc/alertmanager/config/alertmanager.yaml',
                '--storage.path=/alertmanager',
                '--data.retention=120h',
                '--cluster.listen-address=',
                '--web.listen-address=:9093',
                '--web.route-prefix=/',
                '--cluster.peer=' + cfg.name + '-0.alertmanager-operated:9094',
                '--cluster.reconnect-timeout=5m',
              ],
              ports: [
                {
                  containerPort: 9093,
                  name: 'web',
                  protocol: 'TCP',
                },
                {
                  containerPort: 9094,
                  name: 'mesh-tcp',
                  protocol: 'TCP',
                },
                {
                  containerPort: 9094,
                  name: 'mesh-udp',
                  protocol: 'UDP',
                },
              ],
              resources: {
                requests: {
                  memory: '200Mi',
                },
              },
              livenessProbe: {
                failureThreshold: 10,
                httpGet: {
                  path: '/-/healthy',
                  port: 'web',
                  scheme: 'HTTP',
                },
                periodSeconds: 10,
                successThreshold: 1,
                timeoutSeconds: 3,
              },
              readinessProbe: {
                failureThreshold: 10,
                httpGet: {
                  path: '/-/ready',
                  port: 'web',
                  scheme: 'HTTP',
                },
                initialDelaySeconds: 3,
                periodSeconds: 5,
                successThreshold: 1,
                timeoutSeconds: 3,
              },
              volumeMounts: [
                {
                  mountPath: '/etc/alertmanager/config',
                  name: 'config-volume',
                },
                {
                  mountPath: '/etc/alertmanager/certs',
                  name: 'tls-assets',
                  readOnly: true,
                },
                {
                  mountPath: '/alertmanager',
                  name: 'alertmanager-' + cfg.namespace + '-db',
                },
              ],
            },
          ],
          dnsPolicy: 'ClusterFirst',
          nodeSelector: {
            'kubernetes.io/os': 'linux',
          },
          restartPolicy: 'Always',
          schedulerName: 'default-scheduler',
          securityContext: {
            fsGroup: 2000,
            runAsNonRoot: true,
            runAsUser: 1000,
          },
          serviceAccount: 'alertmanager-' + cfg.namespace,
          serviceAccountName: 'alertmanager-' + cfg.namespace,
          terminationGracePeriodSeconds: 120,
          volumes: [
            {
              name: 'config-volume',
              secret: {
                defaultMode: 420,
                secretName: 'alertmanager-' + cfg.namespace + '-config',
              },
            },
            {
              name: 'tls-assets',
              secret: {
                defaultMode: 420,
                secretName: 'alertmanager-' + cfg.namespace + '-tls-assets',
              },
            },
            {
              emptyDir: {},
              name: 'alertmanager-' + cfg.namespace + '-db',
            },
          ],
        },
      },
    },
  },


  clusterRole: {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: {
      name: 'alertmanager-' + cfg.namespace,
    },
    rules: [{
      apiGroups: ['policy'],
      resourceNames: ['alertmanager-' + cfg.namespace + '-psp'],
      resources: ['podsecuritypolicies'],
      verbs: ['use'],
    }],
  },

  clusterRoleBinding: {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      name: 'alertmanager-' + cfg.namespace,
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'alertmanager-' + cfg.namespace,
    },
    subjects: [{
      kind: 'ServiceAccount',
      name: 'alertmanager-' + cfg.namespace,
      namespace: cfg.namespace,
    }],
  },

  podSecurityPolicy: {
    apiVersion: 'policy/v1beta1',
    kind: 'PodSecurityPolicy',
    metadata: {
      name: 'alertmanager-' + cfg.namespace + '-psp',
    },
    spec: {
      allowPrivilegeEscalation: false,
      privileged: false,
      hostNetwork: false,
      hostPID: false,
      runAsUser: {
        rule: 'MustRunAsNonRoot',
      },
      seLinux: {
        rule: 'RunAsAny',
      },
      hostPorts: [
        {
          max: 65535,
          min: 1,
        },
      ],
      fsGroup: {
        ranges: [
          {
            max: 65535,
            min: 1,
          },
        ],
        rule: 'MustRunAs',
      },
      supplementalGroups: {
        ranges: [
          {
            max: 65535,
            min: 1,
          },
        ],
        rule: 'MustRunAs',
      },
      volumes: [
        'configMap',
        'secret',
        'emptyDir',
      ],
    },
  },

  serviceAccount: {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      labels: { alertmanager: cfg.name } + cfg.commonLabels,
      name: 'alertmanager-' + cfg.namespace,
      namespace: cfg.namespace,
    },
  },

  prometheusRule: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PrometheusRule',
    metadata: {
      name: 'alertmanager-' + cfg.namespace + '-rules',
      namespace: cfg.namespace,
      labels: cfg.mixin.ruleLabels + cfg.commonLabels,
    },
    spec: {
      local r = if std.objectHasAll($.mixin, 'prometheusRules') then $.mixin.prometheusRules.groups else [],
      local a = if std.objectHasAll($.mixin, 'prometheusAlerts') then $.mixin.prometheusAlerts.groups else [],
      groups: a + r,
    },
  },

  configSecret: {
    apiVersion: 'v1',
    kind: 'Secret',
    type: 'Opaque',
    metadata: {
      name: 'alertmanager-' + cfg.namespace + '-config',
      namespace: cfg.namespace,
      labels: { alertmanager: cfg.name } + cfg.commonLabels,
    },
    stringData: {
      'alertmanager.yaml': if std.type(cfg.config) == 'object'
      then
        std.manifestYamlDoc(cfg.config)
      else
        cfg.config,
    },
  },

  tlsAssetsSecret: {
    apiVersion: 'v1',
    kind: 'Secret',
    type: 'Opaque',
    metadata: {
      name: 'alertmanager-' + cfg.namespace + '-tls-assets',
      namespace: cfg.namespace,
      labels: { alertmanager: 'alertmanager-' + cfg.namespace } + cfg.commonLabels,
    },
    data: {},
  },

  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: cfg.name,
      namespace: cfg.namespace,
      labels: { alertmanager: cfg.name } + cfg.commonLabels,
    },
    spec: {
      ports: [{
        name: 'web',
        port: 9093,
        targetPort: 'web',
      }],
      selector: { alertmanager: cfg.name } + cfg.selectorLabels,
      sessionAffinity: 'ClientIP',
    },
  },

  serviceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: cfg.name,
      namespace: cfg.namespace,
      labels: { alertmanager: cfg.name } + cfg.commonLabels,
    },
    spec: {
      selector: {
        matchLabels: { alertmanager: cfg.name } + cfg.selectorLabels,
      },
      endpoints: [
        { port: 'web', interval: '30s' },
      ],
    },
  },
}
