### 5G network based on Gradiant Helm charts for UERANSIM+Open5GS in a Raspberry Pi K3s cluster

# Contents of the repo

- Directory _open5gs_: instructions and Helm charts to install and run 5g network on RPi cluster
- Directory _looptest_: examples of reading Open5GS monitoring information from Prometheus
- File `install_helm.sh`: script to install HELM

# How to navigate

### 1. First, install HELM on your management host

If Helm is not installed on your host, install it running the script ```install_helm.sh``` from this repo. We will use Helm for deploying 5G RAN and core network parts, and also to activate/deactivate user equipment (UE) for scaling purposes.

### 2. Then install your 5G network

The basic part is contained in directory [open5gs](./open5gs). It is assumed that you have your k3s deployment on Raspberry Pi 4 or 5 cluster up an running, including monitoring package based on the [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) project. Installing 5G network environment is done in two steps. In the first step ypu will install 5G core network (Open5GS platform). In the second step you will install UERANSIM - RAN network emulator. Both parts are installed using Helm. Initial configuration of UERANSIM deploys with 4 user equipment (UE) terminals attached to the network and active (in the 5G mobile network sense). HELM will also be used to attach new/detach existing UEs to/form the network. Detailed k3s installation guide is available in repository [k3s-taskforce\](https://github.com/dbursztynowski/k3s-taskforce). Therefore, the content of open5gs directory covers only the installation of our 5G environment, and also basic operation of UERANSIM RAN emulator to activate and deactivate user equipment. Refer to file [README](...) for detailed instructions. 

### 3. Then experiment with monitoring the number of AMF sessions and scaling the UPF vertically

Having installed 5G network according to the descriptions in open5gs directory, you can start monitoring and managing 5G core network according to guidelines provided in directory [looptest](./looptest). Actually, our focus is to show how selected service-level metrics of the Open5GS core network can be monitored and used to organize a simple control loop. The loop will vertically scale the UPF container of the 5G core winthout recreating the pod (so called In Place Pod Vertical Scaling - a relatively new feature of Kubernetes, currently with alpha status). One can then extend this example to design and implement more sophisticated control loops. IMPORTANT: Before starting, **read the [README](./looptest/README.md) in the the directory looptest**. If you followed all our guides then in place pod vertical scaling should have been enabled during cluster installation using Ansible, but it can be enabled even now which is also described [here](./looptest/README.md#enable-on-a-running-k3s-cluster) in [README](./looptest/README.md).

