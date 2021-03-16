local defaults = {
  local defaults = self,

  name: 'gitpod',
  namespace: error 'must provide namespace',
  gitpodNamespace: 'default',
  // Remember to add 'app.kubernetes.io/component': 'exporter'
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },
  // Used to override default mixin configs
  mixin: {
    ruleLabels: {},
    _config: {},
  },
};

function(params) {
  local g = self,
  _config:: defaults + params,

  assert std.isObject(g._config.mixin._config),
  mixin:: (import './mixin/mixin.libsonnet') {
    _config+::
      g._config.mixin._config,
  },

  // Service can only find pods within the same namespace, so it gotta be the same where gitpod was deployed.
  agentSmithService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-agent-smith',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'agent-smith',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'agent-smith',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  agentSmithServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-agent-smith',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'agent-smith',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  blobserveService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-blobserve',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'blobserve',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'blobserve',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  blobserveServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-blobserve',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'blobserve',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  contentServiceService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-content-service',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'content-service',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'content-service',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  contentServiceServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-content-service',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'content-service',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

// Not necessary as credit-watcher doesn't expose metrics
  creditWatcherService:: {},
  creditWatcherServiceMonitor:: {},

  // Not necessary as dashboard doesn't expose metrics
  dashboardService:: {},
  dashboardServiceMonitor:: {},

  // Not necessary as db doesn't expose metrics
  dbService:: {},
  dbServiceMonitor:: {},

  // Not necessary as db-sync doesn't expose metrics
  dbSyncService:: {},
  dbSyncServiceMonitor:: {},

    imageBuilderService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-image-builder',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'image-builder',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'image-builder',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  imageBuilderServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-image-builder',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'image-builder',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  messagebusService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-messagebus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'messagebus',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'messagebus',
      },
      ports: [{
        name: 'metrics',
        port: 15692,
      }],
    },
  },

  messagebusServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-messagebus',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'messagebus',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

// Not necessary as proxy doesn't expose metrics
  proxyService:: {},
  proxyServiceMonitor:: {},

  registryFacadeService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-registry-facade',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'registry-facade',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'registry-facade',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  registryFacadeServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-registry-facade',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'registry-facade',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  serverService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-server',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'server',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'server',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  serverServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-server',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'server',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '1m',
        scrapeTimeout: '50s',
      }],
    },
  },

   wsDaemonService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-daemon',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-daemon',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'ws-daemon',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  wsDaemonServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-daemon',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-daemon',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

    wsManagerService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-manager',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-manager',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'ws-manager',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  wsManagerServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-manager',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-manager',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  wsManagerBridgeService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-manager-bridge',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-manager-bridge',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'ws-manager-bridge',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  wsManagerBridgeServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-manager-bridge',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-manager-bridge',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  // Not necessary as ws-proxy doesn't expose metrics
  wsProxyService:: {},
  wsProxyServiceMonitor:: {},

  wsSchedulerService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-scheduler',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-scheduler',
      },
    },
    spec: {
      selector: {
        app: 'gitpod',
        component: 'ws-scheduler',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  wsSchedulerServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-scheduler',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-scheduler',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },


}
