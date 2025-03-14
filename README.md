### 5G network based on Gradiant Helm charts for UERANSIM+Open5GS in a Raspberry Pi K3s cluster

# Contents

- open5gs: install and run 5g network setup on RPi cluster
- TBC ...
- k3subuntu: auxiliary, installation of k3s cluster on Ubuntu VMs on OpenStack (probably to be deleted in the future)
- kube-prometheus: installation manifests, only slightly adjusted to match the configuration of the cluster and the methods of accessing Prometheus and Grafana (probably to be deleted in the future)

# How to navigate

The basic part is contained in directory [open5gs](./open5gs).

It is assumed that you have your k3s deployment using Raspberry Pi 4 or 5 cluster up an running, including a monitoring package based on the [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) project. K3s installation is described in repository [k3s-taskforce\](https://github.com/dbursztynowski/k3s-taskforce). Therefore, the content of open5gs directory covers only the installation and very basic operation of our 5G environment. Refer to the README file therein for remaining instructions.

Having installed 5G netowrk according to the descriptions in open5gs directory, you can start monitoring and managing 5G core network according to guidelines provided in directory [looptest](./looptest). Actually, our focus is to show how selected service-level metrics of the Open5GS core network can be monitored and used to organize a simple control loop. The loop will vertically scale the UPF container of the 5G core. One can then extend this example to design and implement more sophisticated control loops.

**NoteAs** This repo has been derived from another project based on OpenStack installation of k3s. Therefore one can use OpenStack VMs to deploy the ks3 cluster (of course, other Kubernetes flavors can be used without or with minor modifications, but this guide specifically focuses on k3s). Mentioned project served another purposes and required installation of kube-prometheus package, and kube-prometheus directory is a visible artifact of that. We do not plan to use it here, though (we assume kube-prometheus has already been installed in the cluster). Nevertheless, we leave it for the time being, but expect it to be removed in the future.

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
