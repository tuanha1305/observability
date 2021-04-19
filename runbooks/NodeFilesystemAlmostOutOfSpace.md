# NodeFilesystemAlmostOutOfSpace

## Meaning

Metrics coming from node-exporter are suggesting that one of the disk devices of a node is almost out of space.

## Impact

The impact of a full disk can vary depending on which device is full, but it definitely always have a bad impact.

The symptons can be one or more of the list below:
  * Failures on Pre-builds.
  * Failures on workspace startups.
  * Failures to create new files on running workspaces.
  * Failures when running processes that claim disk space on running workspaces.
  * Failures when scheduling new kubernetes resources due to high disk pressure.
  

## Diagnosis

There is two different occasions that leads to full disks, each one with it's own device.

### Full `tmpfs`

> TODO: Why does tmpfs runs full? What is being mounted here?

### Full `/dev/sdb`

That is where we mount all workspaces ephemeral storages. We have no control on how quickly this partition fills up because it is completely dependant on how ours users use Gitpod. We also use this same partition to store container images used by workspaces.
This partition might have become full because one or more workspaces have claimed all, or almost all, disk space available. 

We do run Garbage Collection of container images with the `image-builder` component, but it may not be as frequent as we needed it to be. We also delete workspaces that weren't used for more than 14 days (unless it was pinned), that means that stopped workspaces may also retain big amounts of disk space.

## Mitigation

### Full `tmpfs`

First, check what cluster does the alert comes from, and what node that has a full `tmpfs` device.

![image](https://user-images.githubusercontent.com/24193764/115901955-3b99ef80-a438-11eb-8418-d06c57e42eb9.png)

Go to [https://console.cloud.google.com/](https://console.cloud.google.com/) and find the cluster you want to connect to.

At the top left menu, find `Kubernetes Engine` and click on Clusters:

![image](https://user-images.githubusercontent.com/24193764/113757218-bc42b700-96e8-11eb-9781-3ad789f44d2e.png)

Look for the cluster mentioned in the alert, click on the three dots(`...`) button and then click on Connect:

![image](https://user-images.githubusercontent.com/24193764/115902344-bb27be80-a438-11eb-9c98-8fe196381e14.png)


Copy the command that has appeared in the modal:

![image](https://user-images.githubusercontent.com/24193764/115902598-f6c28880-a438-11eb-9474-1fcd57f86194.png)

Open a Gitpod Workspace and paste that command into a terminal. Alternatively, you can also run this command at your local terminal. You can verify that you've connected correctly by running `kubectx`, you should see your cluster highlighted:

![image](https://user-images.githubusercontent.com/24193764/115902962-66d10e80-a439-11eb-88e1-828d0fed2948.png)


Now just run `kubectl cordon <node>`, substituting `<node>` with the node name that was mentioned in the alert!

---

### Full `/dev/sdb`

First, check what cluster does the alert comes from, and what node that has a full `/dev/sdb` device.

![image](https://user-images.githubusercontent.com/24193764/115919435-34321080-a44f-11eb-8aba-1539a915d7eb.png)

Go to [https://console.cloud.google.com/](https://console.cloud.google.com/) and find the cluster you want to connect to.

At the top left menu, find `Kubernetes Engine` and click on Clusters:

![image](https://user-images.githubusercontent.com/24193764/113757218-bc42b700-96e8-11eb-9781-3ad789f44d2e.png)

Look for the cluster mentioned in the alert, click on the three dots(`...`) button and then click on Connect:

![image](https://user-images.githubusercontent.com/24193764/115902344-bb27be80-a438-11eb-9c98-8fe196381e14.png)


Copy the command that has appeared in the modal:

![image](https://user-images.githubusercontent.com/24193764/115902598-f6c28880-a438-11eb-9474-1fcd57f86194.png)

Open a Gitpod Workspace and paste that command into a terminal. Alternatively, you can also run this command at your local terminal. You can verify that you've connected correctly by running `kubectx`, you should see your cluster highlighted:

![image](https://user-images.githubusercontent.com/24193764/115902962-66d10e80-a439-11eb-88e1-828d0fed2948.png)

If the component `image-builder` runs on the node that run out of space, then `image-builder` delayed Gargage collection is probably the culprit here!

You can run `kubectl get pods -l component=image-builder -o wide` and check if the node matches with the node mentioned in the alert:

![image](https://user-images.githubusercontent.com/24193764/115920041-06010080-a450-11eb-9aab-1e6a3ce1c018.png)

If it does, execute(changing `<image-builder-pod>` with the name of your image-builder pod):

```console 
$ kubectl exec -it <image-builder-pod> -c dind -- sh
$ export DOCKER_HOST=tcp://localhost:2375
$ docker system prune --filter "label!=gitpod.io/image-builder/protected"
```

Follow the command line instructions and wait for the unused images to be cleaned up!


> TODO: What to do if image-builder is not the culprit?
---

## Solution

A couple of solutions could be discussed and implemented in the future:

* Reduce time window between `image-builder` garbage collection.
* Use disk consumption as parameter for garbage collection frequency.
* Backup stopped containers' ephemeral storage and retrieve backup on start-up.