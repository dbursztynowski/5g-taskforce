### 5G network based on Gradiant Helm charts for UERANSIM+Open5GS in a Raspberry Pi K3s cluster

# Contents of the repo

- Directory [_open5gs_](./open5gs): instructions and Helm charts to install and run 5g network on RPi cluster
- Directory [_looptest_](./looptest): examples of reading Open5GS monitoring information from Prometheus
- File [`install_helm.sh`](./install_helm.sh): script to install HELM

# How to navigate

### 1. First, install HELM on your management host

If Helm is not installed on your host, install it running the script [`install_helm.sh`](./install_helm.sh) from this repo. We will use Helm for deploying 5G RAN and core network parts, and also to activate/deactivate user equipment (UE) for scaling purposes.

### 2. Then install your 5G network

Detailed description is contained in directory [open5gs](./open5gs). It is assumed that you have your k3s on Raspberry Pi 4 or 5 cluster up an running, including the monitoring package based on [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) project. Installing 5G network environment is done in two steps. In the first step you will install 5G core network (Open5GS platform). In the second step you will install UERANSIM - RAN network emulator. Installation is straightforward - both parts are installed using Helm. Initial configuration of UERANSIM deploys with 4 user equipments (UE, correspond to mobile terminals) attached to the network and active (in the 5G mobile network sense). Helm will also be used to attach new/detach existing UEs to/from the network. The content [open5gs](./open5gs) of open5gs covers only the installation of the 5G environment and basic operation of UERANSIM RAN emulator to activate and deactivate user equipment. Refer to file [README](...) for detailed instructions. 

### 3. Then experiment with monitoring the number of AMF sessions and scaling the UPF vertically

Having installed 5G network, you can start monitoring and managing 5G core network according to guidelines provided in directory [looptest](./looptest).

Actually, our goal is to illustrate how selected service-level metric can be monitored in Open5GS core network and used in a simple control loop to scale selected network function (container performing the function of UPF in 5G core network). The lab focuses on the monitoring aspect and demonstrating a simple implementation of scaling operation. The control loop will combine monitoring and scaling. You will design it within the project that follows the lab.

The control loop, driven by a selected service-level metric, will operate on resource orchestration level. It will vertically scale the UPF container of the 5G core without recreating the pod (so called In Place Pod Vertical Scaling - a relatively new feature of Kubernetes, currently assigned alpha status). This form of vertical scaling (in-place scaling) is beneficial for statefull services (vertical scaling in not suitable for stateful services). One outcome from the lab and the project is that you will be able to design and implement more sophisticated control loops in Kubernetes. IMPORTANT: Before starting, **read the [README](./looptest/README.md) in the the directory looptest**. If you followed all our installation guides then in place pod vertical scaling should be enabled already, but it can be enabled even now which is described [here](./looptest/README.md#README.md#1-enabling-inplacepodverticalscaling).

