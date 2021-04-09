{
  prometheus+: {
    prometheus+: {
      spec+: {
        remoteWrite+: [{
          url: std.extVar('remote_write_url'),
        }],
      },
    },
  },
}
