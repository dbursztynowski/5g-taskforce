WHAT IS THIS

This is kube-prometheus release 0.14. It uses Prometheus 2.54.1 which is able to scrape metrics form Open5GS functions.
For Prometheus 3.x, either extra configuration of prometheus-prometheus.yaml is needed of Open5GS targets have to be updated. 

These manifests can be used if you have not installed kube-prometheus so far, e.g., working in k3s-taskforce repo. 

==============================================================================

AUXILIRAY INFO

- Setting Prometheus into the push mode by enabling the remoteWrite capability

To enable remoteWrite capability on Prometheus to push metrics to remote receiver without authentication, 
add the the following to the prometheus-prometheus.yaml file, section Prometheus.prometheusSpec. In case of 
authentication problems, refer to https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/config-other-methods/prometheus/remote-write-helm-operator/.

For a more detailed tutorial on using remoteWrite, check also: https://developers.redhat.com/articles/2023/11/30/how-set-and-experiment-prometheus-remote-write#lab_setup. For a description of the remoteWrite/write_relabel options see https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write.

It can be more convinient to deploy kube-prometheus using Helm.

  prometheusSpec:
    remoteWrite:
    - url: "<Your Metrics instance remote_write endpoint>"
#      basicAuth:
#          username:
#            name: kubepromsecret
#            key: username
#          password:
#            name: kubepromsecret
#            key: password
