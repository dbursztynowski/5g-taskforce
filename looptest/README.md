### This page describes a simple experiment that illustrates monitoring of a network function metric in Open5GS using Prometheus and in-place pod vertical scaling based on the current value of the metric.

# Contents

1. [Enabling InPlacePodVerticalScaling](./README.md#enabling-inplacepodverticalscaling)
   
   1.1 [Enable during k3s installation](./README.md#11-enable-during-k3s-installation)

   1.2 [Enable on a running k3s cluster](./README.md#12-enable-on-a-running-k3s-cluster)
   
3. [Testing in-place pod scaling](./README.md#2-testing-in-place-pod-scaling)
   
   2.1 [Scale a test pod](./README.md#21-scale-a-test-pod)

   2.2 [Scale Open5GS UPF function](./README.md#22-scale-open5gs-upf-function)

   2.3 [Retrieve the number of UE sessions set up in the network](./README.md#23-retrieve-the-number-of-ue-sessions-set-up-in-the-network)

4. [Conclusion](./README.md#3-conclusion)
   
# 1. Enabling InPlacePodVerticalScaling

If InPlacePodVerticalScaling has already been enabled in your cluster you can skip this section and go directly to [Testing in-place pod scaling](#testing-in-place-scaling-of-pods). For example, this is the case if you installed k3s cluster using our [Ansible guide](https://github.com/dbursztynowski/k3s-taskforce/tree/master/pi-cluster-install). A quick check if this feature is enabled is to log to the master (control) node of your cluster and run `cat /etc/systemd/system/k3s.service`. If you see `feature-gates=InPlacePodVerticalScaling=true` set for k3s modules as shown below then your cluster is ready for InPlacePodVerticalScaling (for agent nodes, only `kubelet-arg` and `kube-proxy-arg` modules should be configured that way). 

```
ExecStart=/usr/local/bin/k3s \
    server \
... some stuff ...
        '--kube-apiserver-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-controller-manager-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-scheduler-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kubelet-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-proxy-arg=feature-gates=InPlacePodVerticalScaling=true' \
```
Otherwise you need to enable the feature - follow the rest of this section.

> [!Note]
> The latest version of K8s is claimed to have `InPlacePodVerticalScaling` enabled by default, but we haven't checked if this also applies to k3s.
> 
> Pod vertical scaling, as an official Kubernetes term, actually refers to containers, as actual resources like RAM or CPU are assigned to containers (not pods). In this guide, the terms "container scaling" and "pod scaling" are used interchangeably.

## 1.1. Enable during k3s installation

The easiest way is to install k3s with featureGates InPlacePodVerticalScaling enabled. Remember to set the right version of the K3s with the parameter `INSTALL_K3S_VERSION`.

For control nodes run the following (for in-place vertical scaling only the lines with feature-gates matter, and remaining options depend on your specific installation):

```
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.34.4+k3s1 INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 \
  --disable servicelb --disable-cloud-controller \
  --kube-apiserver-arg=feature-gates=InPlacePodVerticalScaling=true \
  --kube-controller-manager-arg=feature-gates=InPlacePodVerticalScaling=true \
  --kube-scheduler-arg=feature-gates=InPlacePodVerticalScaling=true \
  --kubelet-arg=feature-gates=InPlacePodVerticalScaling=true \
  --kube-proxy-arg=feature-gates=InPlacePodVerticalScaling=true" sh -
```

For agent nodes, only the following two lines related to feature-gates need to be included in the installation command compared to the above (refer to the K3s documentation to check the format of a complete installation command for agent nodes):
```
  --kubelet-arg=feature-gates=InPlacePodVerticalScaling=true
  --kube-proxy-arg=feature-gates=InPlacePodVerticalScaling=true
```

If you did not enable in-place pod vertical scaling during the installation, follow the steps below.

## 1.2 Enable in a running k3s cluster

(according to: https://github.com/k3s-io/k3s/issues/12025#issuecomment-2769290290)

1) On server (master) node(s)

- modify file /etc/systemd/system/k3s.service to add feature-gates for apiserver, controller-manager, scheduler, kubelet and kube-proxy as follows

(Note: remaining settings visible are not relevant to in place scaling)
```
ubuntu@k3s01:~$ sudo nano /etc/systemd/system/k3s.service
...
ExecStart=/usr/local/bin/k3s \
    server \
        '--write-kubeconfig-mode' \
        '644' \
        '--disable' \
        'servicelb' \
        '--disable-cloud-controller' \
        '--kube-apiserver-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-controller-manager-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-scheduler-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kubelet-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-proxy-arg=feature-gates=InPlacePodVerticalScaling=true' \
```
- save the file and run
```
ubuntu@k3s01:~$ sudo systemctl daemon-reload
ubuntu@k3s01:~$ sudo systemctl stop k3s.service
ubuntu@k3s01:~$ sudo systemctl start k3s.service
```
2) On each agent node where the feature is to be enabled

(Note: one can enable the feature on a subset of workers, but will need to control the placement of vertically scaled pods.)

- modify file /etc/systemd/system/k3s-agent.service to add feature-gates for kubelet and kube-proxy as follows:
```
ubuntu@k3s02:~$ sudo nano /etc/systemd/system/k3s-agent.service
...
ExecStart=/usr/local/bin/k3s \
    agent \
        '--kubelet-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-proxy-arg=feature-gates=InPlacePodVerticalScaling=true' \
```
- save the file and run:
```
ubuntu@k3s02:~$ sudo systemctl daemon-reload
ubuntu@k3s02:~$ sudo systemctl stop k3s-agent.service
ubuntu@k3s02:~$ sudo systemctl start k3s-agent.service
```
3) Check if in place scaling works - see the next section.

# 2. Testing in-place pod scaling

## 2.1 Scale a test pod

In place pod scaling becomes increasingly better documented than a time ago with official description available [here](https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/). The example provided below derives from an earlier version of that page.

### Define and create the pod
```
$ tee testinplace.yaml << EOT
apiVersion: v1
kind: Namespace
metadata:
  name: tests
---
apiVersion: v1
kind: Pod
metadata:
  name: inplacedemo
  namespace: tests
spec:
  containers:
  - name: inplacedemo
    image: alpine
    imagePullPolicy: IfNotPresent
    command: ["tail", "-f", "/dev/null"]
    resizePolicy:
    - resourceName: "memory"
      restartPolicy: "RestartContainer"
    resources:
      limits:
        cpu: "100m"
        memory: "1Gi"
      requests:
        cpu: "50m"
        memory: "500Mi"
EOT
```
### Run the pod and test in-place scaling

Below, we scale property _limits_ of container CPU resource. We could also scale property _requests_ or scale both properties at a time.

  - scale using kubectl in terminal window
```
$ kubectl apply -f testinplace.yaml
$ kubectl patch -n tests pod inplacedemo --subresource resize --patch \
'{"spec":{"containers":[{"name":"inplacedemo", "resources":{"limits":{"cpu":"150m"}}}]}}'
```
  - scale using kubectl in bash script

    Note: this version works also when resource quotas are passed as variables as $cpu in this example.
```
cpu="150m"
kubectl patch -n $NAMESPACE pod $podname --subresource resize --patch \
 "{\"spec\":{\"containers\":[{\"name\":\"inplacedemo\", \"resources\":{\"limits\":{\"cpu\":\"$cpu\"}}}]}}"
```

## 2.2 Scale Open5GS UPF function

Below, it is assumed that all components (Open5GS/UERANSIM and the monitoring platform) have been installed following our instructions. Otherwise some details may differ and adaptations may be required.

<pre>
# get pods to have their names displayed

<font color="#26A269"><b>ubuntu@labs</b></font>:<font color="#12488B"><b>~/labs/5gtask</b></font>$ kubectl get pods
NAME                                       READY   STATUS    RESTARTS        AGE
open5gs-amf-57c6c6c65b-vhh8c               1/1     Running   0               4h39m
open5gs-ausf-bcfd48966-bwr2q               1/1     Running   0               4h39m
open5gs-bsf-796ccbfc56-vvvmj               1/1     Running   0               4h39m
open5gs-mongodb-9df4bcfdb-pqr5b            1/1     Running   0               4h39m
open5gs-nrf-54dd7bcd5-f74d5                1/1     Running   0               4h39m
open5gs-nssf-6577c78cc9-q4vk4              1/1     Running   0               4h39m
open5gs-pcf-86678b795b-d9pz2               1/1     Running   5 (4h36m ago)   4h39m
open5gs-populate-84c9dd744c-mxcr8          1/1     Running   0               4h39m
open5gs-scp-789c9b466c-z7lqn               1/1     Running   0               4h39m
open5gs-smf-74845db7cb-bjjxd               1/1     Running   0               4h39m
open5gs-udm-8674db49b9-swxhl               1/1     Running   0               4h39m
open5gs-udr-77fd7748fb-nwwkk               1/1     Running   5 (4h37m ago)   4h39m
<font color="#DC143C"><b>open5gs-upf-8444fdb48d-sv26l               1/1     Running   0               4h39m</b></font>
open5gs-webui-55dbd67878-rpwk9             1/1     Running   0               4h39m
ueransim-gnb-d7d765f99-zfcdd               1/1     Running   0               4h7m
ueransim-gnb-ues-5b68cf9b78-gd4lr          1/1     Running   1 (4h7m ago)    4h7m
ueransim-ues-additional-6bcb88756c-ldjwq   1/1     Running   0               4h5m
   
# patch (scale) the UPF pod (here, we scale the property 'limits' of the container CPU)

<font color="#26A269"><b>ubuntu@labs</b></font>:<font color="#12488B"><b>~/labs/5gtask</b></font>$ kubectl patch -n default pod <font color="#26A269"><b>open5gs-upf-8444fdb48d-sv26l</b></font> --subresource resize --patch  \
&apos;{&quot;spec&quot;:{&quot;containers&quot;:[{&quot;name&quot;:&quot;<font color="#DC143C"><b>open5gs-upf</b></font>&quot;, &quot;resources&quot;:{&quot;limits&quot;:{&quot;cpu&quot;:&quot;150m&quot;}}}]}}&apos;
pod/<font color="#26A269"><b>open5gs-upf-8444fdb48d-sv26l</b></font> patched
   
# check if the pod has been resized as requested (we see a change from 100m to 150m)

<font color="#26A269"><b>ubuntu@labs</b></font>:<font color="#12488B"><b>~/labs/5gtask</b></font>$ kubectl get pods/<font color="#26A269"><b>open5gs-upf-8444fdb48d-sv26l</b></font> \
-o=jsonpath=&apos;{.status.containerStatuses[0].resources}&apos; | jq
<b>{</b>
<b>  </b><font color="#12488B"><b>&quot;limits&quot;</b></font><b>: {</b>
<b>    </b><font color="#12488B"><b>&quot;cpu&quot;</b></font><b>: </b><font color="#26A269">&quot;150m&quot;</font>
<b>  },</b>
<b>  </b><font color="#12488B"><b>&quot;requests&quot;</b></font><b>: {</b>
<b>    </b><font color="#12488B"><b>&quot;cpu&quot;</b></font><b>: </b><font color="#26A269">&quot;50m&quot;</font>
<b>  }</b>
<b>}</b>
<font color="#26A269"><b>ubuntu@labs</b></font>:<font color="#12488B"><b>~/labs/5gtask</b></font>$</pre>

## 2.3 Retrieve the number of UE sessions set up in the network

As an example, we read the number of active UE sessions registered in the AMF function. Prometheus scrapes this metric from the AMF target every 15 seconds. We read it by querying Prometheus. Below, several examples of reading metric value are given. They can be adapted to implement more complex control loops, e.g., in bash or Python.

### Enable Prometheus to scrape Open5GS metrics

If you installed kube-prometheus according to our guidelines from [k3s-taskforce](https://github.com/dbursztynowski/k3s-taskforce) then you can skip this subsection. 

> [!Note]
> Open5GS Prometheus targets send metrics only in text format (old protocol version). Prometheus releases starting from 3.0 need to be configured to fallback to this older version. To this end `fallbackScrapeProtocol` of the `scrapeClasses` attribute of the Prometheus Operator has to be set to `PrometheusText0.0.4`. To achieve this (assuming you are using kube-prometheus), first modify the `prometheus-prometheus.yaml` spec section of `Prometheus` CRD in the manifest file adding the `scrapeClasses` attribute with `fallbackScrapeProtocol` set to `PrometheusText0.0.4` as shown below. The details are given below.

* Update the manifest `prometheus-prometheus.yaml` by setting the `scrapeClasses` attribute 
```
spec
  # scrapeClasses to be added
  scrapeClasses:
  - name: open5gs-scrape
    default: true
    fallbackScrapeProtocol: PrometheusText0.0.4 # Sets the fallback protocol
```

<ul>
   Restarting Prometheus as instructed below should only be performed if you are updating a running kube-prometheus instance. Otherwise, skip this step. Apply the updated manifest and force restart all pods in the stateful set `prometheus-k8s` (the pods are named `prometheus-k8s-X`). The steps are as follows.
</ul>

* Restarting Prometheus

  - apply the new spec
    ```
    $ kubectl apply -f prometheus-prometheus.yaml
    ```

  - restart all pods of the stateful set `prometheus-k83` - use one of the two options below
    - option 1: rollout restart of the stateful set (more general solution)

    ```
    $ kubectl -n monitoring rollout restart statefulset/prometheus-k8s
    ```

    - option 2: delete manually all pods of the stateful set `prometheus-k8s` (in our case there will be one pod)
     
    ```
    $ kubectl delete -n monitoring pod prometheus-k8s-0
    $ kubectl delete -n monitoring pod prometheus-k8s-1
    ...
    ```

### Retrieve the metric using a browser
```
http://10.254.186.64:9090/api/v1/query?query=amf_session{service="open5gs-amf-metrics",namespace="default"}
```

### Retrieve the metric using curl in Linux

- directly from command line (here, Open5GS runs in default namespace)
```
# complete record
curl 10.254.186.64:9090/api/v1/query -G -d 'query=amf_session{service="open5gs-amf-metrics",namespace="default"}' | jq

# only the value (option -s stands for "silent")
curl -s 10.254.186.64:9090/api/v1/query -G -d 'query=amf_session{service="open5gs-amf-metrics",namespace="default"}' | jq '.data.result[0].value[1]' | tr -d '"'
```

- embedded in a bash script (here, NAMESPACE is the namespace of Open5GS; PROMETHEUS_ADDR is a reachable address of Prometheus)
```
# read the value of metric amf_sessions from Prometheus;
query="query=amf_session{service=\"open5gs-amf-metrics\",namespace=\"$NAMESPACE\"}"
echo -e "\nquery:" ${query}
amf_sessions=$(curl -s ${PROMETHEUS_ADDR}:9090/api/v1/query -G -d \
     ${query} | jq '.data.result[0].value[1]' | tr -d '"')
```

### Retrieve the metric using curl in Windows
(here, Open5GS runs in default namespace)
```
curl 10.254.186.64:9090/api/v1/query -G -d "query=amf_session{service=\"open5gs-amf-metrics\",namespace=\"default\"}"
```

# 3. Conclusion

You already know how to monitor the number of UE sessions and how Open5GS functions (more specifically, their containers) can be scaled vertically without restarting the pod. Vertical scaling can be usefull for example in case of stateful functions, i.e., functions whose state can not be recreated easily after restarting the pod. This is the case with the UPF function in Open5GS as a UPF container keeps the information about existing UE data plane sessions in RAM and not in persistent memory.

As a next step, you can realise a small project to design a simple scaler of Open5GS functions based on the number of UE sessions in the network. In the simplest case, it can monitor the amf_session metric and scale the UPF container. This may correspond to a scenario where an increase in the number of sessions indicates that the data plane load in the UPF will increase soon. Anticipating this, we are adding compute resources to the UPF container to handle this increase. A slightly more complex scenario could involve scaling UPF and AMF together, perhaps with some operation dependency, e.g., requiring that the UPF pod be scaled first, and the AMF pod only after we can confirm that the UPF pod has been scaled successfully. Notice such a control of the sequence of operations can not be achieved with standard Kubernetes autoscalers - Horizontal and Vertical Pod Autoscalers (HPA, VPA).

> [!Note]
> If you want to scale other functions than UPF, you need to update the manifest templates of the corresponding deployments to declare `resources.requests` and/or `resources.limits` properties for the containers being scaled. This is required because best effort containers cannot be scaled vertically (best effort container is one that has neither _requests_ nor _limits_ are declared in its manifest, which is the default setting in our Open5GS Helm charts). Check the UPF configuration file `open5gs/open5gs-228/charts/open5gs-upf/values.yaml` in your Helm charts (line ~ 220) to see how this can look like.
