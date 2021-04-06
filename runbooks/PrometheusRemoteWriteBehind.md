# PrometheusRemoteWriteBehind

## Meaning

Prometheus records the timestamp of the last succesful remote-write request for each remote-write URL. 
Prometheus has been failing to send newer metrics to one or more of those remote-write URLs and is falling behind.

## Impact

It's common that remote-storage backends for Prometheus metrics is the place where Grafana will query metrics with wider coverage, usually used to centralize metrics and data visualization from several different clusters at the same time. If Prometheus is failing to send metrics to the remote-storage backend, it means that the Grafana instance that queries this backend will present missing data.

While alerts are being routed by an Alertmanager instance that lives within the same cluster as Prometheus, alerts still work with no impact, but it's common that we need to visualize metrics on Grafana during incidents. Thus, This alert has a big impact into our monitoring solution and is considered a critical one.

## Diagnosis

Failing to send remote-write requests always means a networking issue between Prometheus and the Remote-Storage Backend.
At Gitpod, we run our Prometheus within the same clusters where our Gitpod installations are hosted, while our remote-storage backend lives in a separated cluster that we call `Monitoring-Central`.

To discover where is the problem, check networking issues according to your platform:

### GKE

If you run multiple clusters on multiple regions like we do, the remote-storage backend will need an external address that Prometheus can reach. 
Creating a `Service` for the remote-storage of type `Internal Load Balancer`, while also enabling global access should do the trick.

If that is not how your remote-storage backend was configured, then Prometheus won't be able to reach it and it would explain this Alert being triggered.

To solve it, make sure your `Service` resource for the remote-storage backend has the following annotations:
```yaml
annotations:
  networking.gke.io/internal-load-balancer-allow-global-access: "true"
  networking.gke.io/load-balancer-type: Internal
```
