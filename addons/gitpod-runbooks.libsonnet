local commonRunbookURLPatern = 'https://www.notion.so/gitpod/%s';

{
  values+:: {
    prometheus+: {
      mixin+: {
        _config+: {
          runbookURLPattern: commonRunbookURLPatern,
        },
      },
    },
    alertmanager+: {
      mixin+: {
        _config+: {
          runbookURLPattern: commonRunbookURLPatern,
        },
      },
    },
    kubeStateMetrics+: {
      mixin+: {
        _config+: {
          runbookURLPattern: commonRunbookURLPatern,
        },
      },
    },
    kubernetesControlPlane+: {
      mixin+: {
        _config+: {
          runbookURLPattern: commonRunbookURLPatern,
        },
      },
    },
    nodeExporter+: {
      mixin+: {
        _config+: {
          runbookURLPattern: commonRunbookURLPatern,
        },
      },
    },
    prometheusOperator+: {
      mixin+: {
        _config+: {
          runbookURLPattern: commonRunbookURLPatern,
        },
      },
    },
  },
}
