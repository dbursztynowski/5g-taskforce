### 5G network based on Gradiant Helm charts for UERANSIM+Open5GS on Raspberry Pi cluster

# Contents

- open5gs: install and run 5g network setup on RPi cluster
- TBC ...
- k3subuntu: auxiliary, installation of k3s cluster on Ubuntu VMs on OpenStack (probably to be deleted in the future)
- kube-prometheus: installation manifests, only slightly adjusted to match the configuration of the cluster and the methods of accessing Prometheus and Grafana (probably to be deleted in the future)

# How to navigate

The basic part is contained in directory open5gs. It is assumed that you have your k3s cluster on Raspberry Pi 4 or 5 up an running, including Prometheus package based on the [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) project. K3s installation is described in repository [k3s-taskforce\](https://github.com/dbursztynowski/k3s-taskforce). Therefore, open5gs covers only the installation and operation of our 5G environment on a basic level. Refer to the README file therein for remaining instructions. 

As this repo has been derived from another project based on OpenStack installation, one can use OpenStack VMs to deploy ks3 cluster (of course, other Kubernetes flavors can be used without or with minor modifications, but this guide specifically focuses on k3s). Mentioned project served another purposes and required installation of kube-prometheus package. kube-prometheus directory is an artifact of that, but we do not plan to use it here (w e assume kube-prometheus has already been installed in the cluster). Nevertheless, we leave it for the time being, but expect it to be removed in the future.

# Other hints
### (may or may not be useful for you)

### UERANSIM docker files

- https://github.com/Borjis131/docker-ueransim/tree/main/images/ue

### Other interesting links
- Security and observability with Cilium on my 5G network
https://luislogs.com/posts/security-and-observability-with-cilium-on-my-5g-network/

-  Cloud-Enabled Deployment of 5G Core Network with Analytics Features
https://www.mdpi.com/2076-3417/14/16/7018

- NGAP Load Balancing with LoxiLB (gNB-AMF/SCTP)
  (usese my5g-RANTester: https://github.com/my5G/my5G-RANTester.git )
https://www.loxilb.io/post/ngap-load-balancing-with-loxilb
