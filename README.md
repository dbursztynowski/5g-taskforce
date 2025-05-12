### 5G network based on Gradiant Helm charts for UERANSIM+Open5GS in a Raspberry Pi K3s cluster

# Contents of the repo

- Directory _open5gs_: instructions and Helm charts to install and run 5g network on RPi cluster
- Directory _looptest_: examples of reading Open5GS monitoring information from Prometheus
- File `install_helm.sh`: script to install HELM. You can run it for any case.

# How to navigate

### 1. First, install HELM on your management host

If HELM is not installed on your host, install it running the script ```install_helm.sh``` from this repo. We will use helm for deploying 5G RAN and core network parts, and also to activate/deactivate user equipment (UE) for scaling purposes.

### 2. Then install your 5G network

The basic part is contained in directory [open5gs](./open5gs). It is assumed that you have your k3s deployment using Raspberry Pi 4 or 5 cluster up an running, including a monitoring package based on the [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) project. K3s installation is described in repository [k3s-taskforce\](https://github.com/dbursztynowski/k3s-taskforce). Therefore, the content of open5gs directory covers only the installation and very basic operation of our 5G environment. Refer to the [README](...) file therein for remaining instructions. After installing Open5GS, you will have to install RAM network emulator, UERANSIM. It is recommended to use HELM for that. Initial configuration installs UERANSIM with 4 user equipment (UE) termnals attached and active. HELM will also be used to attach new/detach existing UEs to/form the network.

### 3. Then experiment with monitoring the number of AMF sessions and scaling the UPF vertically

Having installed 5G network according to the descriptions in open5gs directory, you can start monitoring and managing 5G core network according to guidelines provided in directory [looptest](./looptest). Actually, our focus is to show how selected service-level metrics of the Open5GS core network can be monitored and used to organize a simple control loop. The loop will vertically scale the UPF container of the 5G core winthout recreating the pod (so called In Place Pod Vertical Scaling - a relatively new feature of Kubernetes, currently with alpha status). One can then extend this example to design and implement more sophisticated control loops. IMPORTANT: Before starting, **read the [README](./looptest/README.md) in the the directory looptest**. If you followed all our guides then in place pod vertical scaling should have been enabled during cluster installation using Ansible, but it can be enabled even now which is also described [here](./looptest/README.md#enable-on-a-running-k3s-cluster) in [README](./looptest/README.md).

