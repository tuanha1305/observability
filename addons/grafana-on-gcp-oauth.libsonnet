{
  grafana+: {
    // Certmanager must be installed in the cluster already!
    certificate: {
      apiVersion: 'cert-manager.io/v1alpha2',
      kind: 'Certificate',
      metadata: {
        name: 'grafana',
        namespace: std.extVar('namespace'),
      },
      spec: {
        dnsNames: [
          std.extVar('dns_name'),
        ],
        issuerRef: {
          kind: 'ClusterIssuer',
          name: 'letsencrypt-issuer',
        },
        secretName: 'grafana-certificate',
      },
    },

    ingressService: $.grafana.service {
      metadata+: {
        name: 'grafana-loadbalancer',
        annotations+: {
          'cloud.google.com/backend-config': '{"ports": {"3000":"' + $.grafana.backendOAuth.metadata.name + '"}}',  // same name as backend-config
        },
      },
      spec+: {
        type: 'NodePort',
        ports: std.map(
          function(p) p {
            nodePort: std.parseInt(std.extVar('grafana_ingress_node_port')),
          }
          , super.ports
        ),
      },
    },

    ingress: {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'kubernetes.io/ingress.global-static-ip-name': std.extVar('gcp_external_ip_address'),
          'kubernetes.io/ingress.class': 'gce',
          'cert-manager.io/cluster-issuer': $.grafana.certificate.spec.issuerRef.name,
        },
        labels: $.grafana.service.metadata.labels,
        name: 'grafana',
        namespace: std.extVar('namespace'),
      },
      rules: [{
        host: std.extVar('dns_name'),  // gcp's external ip address
        http: {
          paths: [{
            backend: {
              serviceName: $.grafana.ingressService.metadata.name,  // same name put on service resource
              servicePort: 3000,
            },
            path: '/*',
          }],
        },

      }],
      tls: [{
        hosts: [
          std.extVar('dns_name'),
        ],
        secretName: $.grafana.certificate.spec.secretName,
      }],
    },

    backendOAuthSecret: {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: 'grafana-oauth',
        namespace: std.extVar('namespace'),
        labels: $.grafana.service.metadata.labels,
      },
      data: {
        client_id: std.base64(std.extVar('IAP_client_id')),  // Get from IAP console as variable, needs to be encoded with base64
        client_secret: std.base64(std.extVar('IAP_client_secret')),  // Get from IAP console as variable, needs to be encoded with base64
      },
    },

    backendOAuth: {
      apiVersion: 'cloud.google.com/v1',
      kind: 'BackendConfig',
      metadata: {
        name: 'grafana',
        namespace: std.extVar('namespace'),
      },
      spec: {
        iap: {
          enabled: true,
          oauthclientCredentials: {
            secretName: $.grafana.backendOAuthSecret.metadata.name,
          },
        },
      },
    },
  },
}
