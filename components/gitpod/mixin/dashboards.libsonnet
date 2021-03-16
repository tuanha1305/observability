{
  grafanaDashboards+:: {
    'gitpod-overview.json': (import 'dashboards/gitpod-overview.json'),

    // Components
    'gitpod-component-agent-smith.json': (import 'dashboards/components/agent-smith.json'),
    'gitpod-component-blobserve.json': (import 'dashboards/components/blobserve.json'),
    'gitpod-component-content-service.json': (import 'dashboards/components/content-service.json'),
    'gitpod-component-credit-watcher.json': (import 'dashboards/components/credit-watcher.json'),
    'gitpod-component-dashboard.json': (import 'dashboards/components/dashboard.json'),
    'gitpod-component-db.json': (import 'dashboards/components/db.json'),
    'gitpod-component-db-sync.json': (import 'dashboards/components/db-sync.json'),
    'gitpod-component-image-builder.json': (import 'dashboards/components/image-builder.json'),
    'gitpod-component-messagebus.json': (import 'dashboards/components/messagebus.json'),
    'gitpod-component-proxy.json': (import 'dashboards/components/proxy.json'),
    'gitpod-component-registry-facade.json': (import 'dashboards/components/registry-facade.json'),
    'gitpod-component-server.json': (import 'dashboards/components/server.json'),
    'gitpod-component-ws-daemon.json': (import 'dashboards/components/ws-daemon.json'),
    'gitpod-component-ws-manager-bridge.json': (import 'dashboards/components/ws-manager-bridge.json'),
    'gitpod-component-ws-manager.json': (import 'dashboards/components/ws-manager.json'),
    'gitpod-component-ws-proxy.json': (import 'dashboards/components/ws-proxy.json'),
    'gitpod-component-ws-scheduler.json': (import 'dashboards/components/ws-scheduler.json'),

    // SLOs
    'gitpod-slo-login.json': (import 'dashboards/SLOs/login.json'),
  },
}
