# KubeStateMetricsListErrors

## Meaning

The component [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) which is responsible to read the state of a kubernetes cluster and expose metrics related to such state is failing to get responses from kube-apiserver at an elevated rate.

## Impact

Kube-state-metrics is not able to expose metrics about kubernetes state, maybe only about some specific resources or entirely. While it doesn't mean direct impact to our users, it can affect our monitoring system.

If kube-state-metrics isn't able to query the state of resources such as `Deployments` and `Pods`, then we won't be able to receive alerts about pods that may be stuck on `CrashLoopBackoff`. This is considered a `critical` alert because our monitoring solution is vital for keeping Gitpod reliable.

## Diagnosis

We've noticed that kube-prometheus, which serves the foundation for our monitoring stack, deploys by default a version of kube-state-metrics, [v2.0.0-rc1](https://github.com/prometheus-operator/kube-prometheus/blob/f5f72e1b5011830da821a7f6afff667c27b6fc37/jsonnet/kube-prometheus/versions.json#L5), which is [incompatible with our kubernetes cluster version](https://github.com/kubernetes/kube-state-metrics#compatibility-matrix) (we use 1.17 today). Transforming this super important alert into a super noisy one, thus not really useful.

## Mitigation

The [agreed mitigation is to momentarily silence the alert](https://gitpod.slack.com/archives/C01KGM9EBD4/p1617220043139300), hoping that a real solution is implemented soon. We're not going to completely remove the alert because it is quite an important one if we can make it work properly.

To silence the alert, follow these steps below

---
Identify which cluster triggered the alert, this can be done by reading the alert sent to slack.

Like this example, one can see that the alert was triggered at the US cluster at staging.
![image](https://user-images.githubusercontent.com/24193764/113757147-a7662380-96e8-11eb-979f-9ca52f263417.png)

Go to [https://console.cloud.google.com/](https://console.cloud.google.com/) and find the cluster you want to connect to.

At the top left menu, find `Kubernetes Engine` and click on Clusters:
![image](https://user-images.githubusercontent.com/24193764/113757218-bc42b700-96e8-11eb-9781-3ad789f44d2e.png)


Change the project to the one where your cluster belongs to, like `Staging` for this example, find the correct cluster, click on the three dots on the right and then click on `Connect`:
![image](https://user-images.githubusercontent.com/24193764/113757316-da101c00-96e8-11eb-9841-2c14119f3075.png)

It will open a modal with a button where you can copy the command to connect to that cluster:
![image](https://user-images.githubusercontent.com/24193764/113757365-e5fbde00-96e8-11eb-89c9-8555f51c3d69.png)

Open a Gitpod workspace or a terminal at your local environment and run the copied command, you should see a successful message like this one after running it:
![image](https://user-images.githubusercontent.com/24193764/113757408-f318cd00-96e8-11eb-9a86-81986ae1abad.png)

The next step is to access alertmanager's UI. To do that you can run the command:

`kubectl port-forward -n cluster-monitoring alertmanager-main-0 9093`

If you run the command on a Gitpod workspace, click on Open Browser to access the UI. If you run it locally, then access [http://localhost:9093](http://localhost:9093)
![image](https://user-images.githubusercontent.com/24193764/113757472-05930680-96e9-11eb-96df-9f8c7ab8903c.png)

Once you've accessed Alertmanager's UI, apply a filter with `alertname="KubeStateMetricsListErrors"` and then click on one of the available Silence buttons:
![image](https://user-images.githubusercontent.com/24193764/113757520-15124f80-96e9-11eb-8dff-df50cb138087.png)

On the Silence page, there are a few fields that you need to pay attention to:

- Duration - The amount of time the alert will remain silenced, we're suggesting 30d, but feel free to choose your period
- Matchers - Alerts with matching labels will be silenced, to silence `KubeStateMetricsListErrors` fill the fields as shown in the image below.
- Creator - Write your own name.
- Comment - Explain why the alert is being silenced, we suggest the text:

```markdown
We're deploying an incompatible kube-state-metrics with our k8s cluster. This is a known bug for ksm, please see: https://github.com/kubernetes/kube-state-metrics#compatibility-matrix

We're silencing for a short period hoping that this bug is fixed upstream or that we're able to upgrade our k8s clusters.
```
- The last step is to click on `Create`

![image](https://user-images.githubusercontent.com/24193764/113757654-3d9a4980-96e9-11eb-859e-29c93213c1ef.png)

And done, you'll be redirected to a page with your silence in action:

![image](https://user-images.githubusercontent.com/24193764/113757703-4ee35600-96e9-11eb-8d00-3a08e05be459.png)


## Solution

We have a couple of options for a real solution here, where none of them is really a trivial one.

### Option 1

Work upstream and make kube-state-metrics compatible with kubernetes clusters on older versions.

### Option 2

Update our clusters to at least 1.19, which is the first version that kube-state-metrics:v2.0.0-rc1 is compatible with.