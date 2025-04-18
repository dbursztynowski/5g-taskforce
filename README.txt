VERY ADDITIONAL/AUXLIARY HINTS

==============================================
- checking which featureGates are enabled
  kubectl get --raw /metrics | grep kubernetes_feature_enabled

==============================================
- install kube-prometheus
https://github.com/prometheus-operator/kube-prometheus
(check the compatibility matrix at this link and select the right varsion one for you to wget as shown below)

# change directory where you want to store your kube-prometheus manifests, e.g. kube-prometheus
# (we use directory kube-prometheus-2 where "2" denotes a varsion containing release 2.xy of Prometheus because 
  Prometheus 3.x does not work well un our case)
# There are two options:

# OPTION1: clone whole branch and extract what is needed
$ git clone -b release-0.14 --single-branch https://github.com/prometheus-operator/kube-prometheus.git
# and then extract directory "manifests" with oll files and subdirectories from there and remove the rest of the repo

# OPTION2: use browser and download only the needed directory "manifests"
1. Open browser window in your VM and go to:
   https://download-directory.github.io/
2. Copy-paste address https://github.com/prometheus-operator/kube-prometheus/tree/release-0.14/manifests in 
   the text window and click Enter key. File named 'prometheus-operator kube-prometheus release-0.14 manifests.zip'
   will be stored in the directory ~/Downloads.
3. Extract the contents of this file, rename resulting directory to "manifests", and move it to your preferred location.

# You now have all kube-prometheus manifests stored locally.
# Note: you may need to follow the instructions from the SPIW lab k3s install guide where we update
  Prometheus and Grafana cluster roles, services and network policies, Grafana deployment (update 
  readinessProbe), and Prometheus/Grafana deloyments to add persistent storage.

# Installing the stack in three steps:
$ kubectl apply --server-side -f manifests/setup
$ kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
$ kubectl apply -f manifests/

- tear down the stack
$ kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup

=================================================
- Setting Prometheus into the push mode by enabling the remoteWrite capability

To enable remoteWrite capability on Prometheus to push metrics to remote receiver without authentication, 
add the the following to the prometheus-prometheus.yaml file, section Prometheus.prometheusSpec. In case of 
authentication problems, refer to https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/config-other-methods/prometheus/remote-write-helm-operator/.

For a more detailed tutorial on using remoteWrite, check also: https://developers.redhat.com/articles/2023/11/30/how-set-and-experiment-prometheus-remote-write#lab_setup
For a description of the remoteWrite/write_relabel options see https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write.
