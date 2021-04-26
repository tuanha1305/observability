# GitpodLoginErrorBudgetBurn

## Meaning

The overall availability of the Login functionality isn't guaranteed anymore. There may be too many errors returned by the responsible components or by third-party that the login feature depends on. Without being able to login, users won't be able to use any of our services!

## Impact

The `GitpodLoginErrorBudgetBurn` is an [SLO-based alert](https://sre.google/workbook/alerting-on-slos/), that means that the alert is triggered with different severities depending of how quickly we're burning our Error Budget. As we trigger this alert on different burn rates, we also respond to it differently to each situation.

### `warning`

We are burning our error budged in a worrying rate, but it can wait in case it's an inconvenient time for the person on-call. If the `GitpodLoginErrorBudgetBurn` alert is triggered with `warning` severity, then it means we'll waste the whole monthly error budget in between 10 to 30 days. 

### `critical`

We are burning our error budged in a very worrying rate and it must be managed immediately. If the `GitpodLoginErrorBudgetBurn` alert is triggered with `critical` severity, then it means we'll waste the whole monthly error budget in between 2 to 5 days. 

## Diagnosis

To certify that the alert is valid, check the Grafana dashboard `Gitpod / SLOs / Login`, the first panel should have a lot of red on it! The more red, more failure ratio we're receiving over time.

![image](https://user-images.githubusercontent.com/24193764/116142885-cf75f080-a6b0-11eb-9cc8-04e9d835f103.png)


## Mitigation

As an SLO-based alert, we do know that it is a very impactful one for our users. On the other hand, we do not receive details on why that is happening! The mitigation here is to do some debugging work or escalate and call the incident response team. 

For debugging, there is a couple of things one could look at to find the culprit(s). Starting with our dashboard:

#### Cluster specific 

Go to `Gitpod / SLOs / Login` and look at the lower level panels, for example Failure Ratio per cluster.

![image](https://user-images.githubusercontent.com/24193764/116144779-cd149600-a6b2-11eb-80a9-9603baad4005.png)

If failure is clearly happening in a single cluster, it may suggest that the error is very specific for the conditions that cluster is in. 
Look at other dashboards tagged with `kubernetes-mixin` or `node-exporter-mixin` and look for possible unhealthy systems. 

![image](https://user-images.githubusercontent.com/24193764/116145324-94c18780-a6b3-11eb-8dcc-4f886dbf6b08.png)

Another one that might give some good leads is `Gitpod / Component / Server`, since `server` is the component responsible for logins. Look for anything that looks off, for example sudden spikes or drops.

![image](https://user-images.githubusercontent.com/24193764/116145772-1c0efb00-a6b4-11eb-8624-648624cb4872.png)


#### Auth provider specific 

If you notice that failures are not cluster specific, but Auth Provider, then a good place to look for leads is going to be logs. 

![image](https://user-images.githubusercontent.com/24193764/116147227-d5ba9b80-a6b5-11eb-8983-dc699551ac15.png)

Go to GCP's Log's Explorer and search for logs with the following filter:

```
labels.k8s-pod/component="server"
severity=ERROR
```

Read through the logs and look for anything that might explain the failures.

### Escalation

In case you don't find anything or you're not confident with debugging, then it make sense to escalate the alert, but please take into consideration the severity!

#### `warning`

Since it is not that urgent, open a [Github Issue](https://github.com/gitpod-io/gitpod/issues/new/choose) explaining everything you found out and communicate the problem to the team. If the problem was found during normal shift, please try to find someone to assign the issue to.

#### `critical`

Please call incident response following our [process](https://www.notion.so/gitpod/Incident-Response-972e24567d254283b6a0cc8aeb4ba6c1).