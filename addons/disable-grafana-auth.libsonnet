{
  grafana+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers: std.map(
              function(c) c {
                env+: if c.name == 'grafana' then
                  [
                    {
                      name: 'GF_AUTH_ANONYMOUS_ENABLED',
                      value: true,
                    },
                    {
                      name: 'GF_AUTH_ANONYMOUS_ORG_ROLE',
                      value: 'Admin',
                    },
                    {
                      name: 'GF_AUTH_DISABLE_LOGIN_FORM',
                      value: true,
                    },
                  ]
                else [],
              }
              , super.containers
            ),
          },
        },
      },
    },
  },
}
