### 5G network based on Gradiant Helm charts for UERANSIM+Open5GS in a Raspberry Pi K3s cluster

# Contents of the repo

- Directory [_open5gs_](./open5gs): instructions and Helm charts to install and run 5g network on RPi cluster
- Directory [_looptest_](./looptest): examples of reading Open5GS monitoring information from Prometheus
- File [`install_helm.sh`](./install_helm.sh): script to install HELM
- Directory [_spiw-lab3_](./spiw-lab3): Lab3 guide for the SPIW course students

# How to navigate

### 1. First, install HELM on your management host

If Helm is not installed on your host, install it running the script [`install_helm.sh`](./install_helm.sh) from this repo. We will use Helm for deploying 5G RAN and core network parts, and also to activate/deactivate user equipment (UE) for scaling purposes.

### 2. Then install your 5G network

Detailed description is contained in directory [open5gs](./open5gs). Here, we assume that you have your k3s on Raspberry Pi 4 or 5 cluster up an running, including the monitoring package based on [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) project (full installation of k3s is described [here](https://github.com/dbursztynowski/k3s-taskforce)). Installing 5G network environment is done in two steps. In the first step you will install 5G core network (Open5GS platform). In the second step you will install UERANSIM - RAN network emulator. Installation is straightforward - both parts are installed using Helm. Initial configuration of UERANSIM deploys with 4 user equipments (UE, correspond to mobile terminals) attached to the network and active (in the 5G mobile network sense). Helm will also be used to attach new/detach existing UEs to/from the network. The content [open5gs](./open5gs) of open5gs covers only the installation of the 5G environment and basic operation of UERANSIM RAN emulator to activate and deactivate user equipment. For detailed instructions, please refer to the [README](open5gs/README.md) file in the open5gs directory.

### 3. Then monitor the number of AMF sessions and scale the UPF vertically

Having installed 5G network, you can start monitoring and managing 5G core network according to guidelines provided in directory [looptest](./looptest).

> [!Important]
> To get ready, **read the [README](./looptest/README.md) file in the the looptest directory**. If previously you followed all our installation guides then _in place pod vertical scaling_ should be enabled already. If not it can be enabled now which is described [here](./looptest/README.md#README.md#1-enabling-inplacepodverticalscaling).

Actually, our goal is to illustrate how a service-level metric can be monitored in Open5GS core network and used in a simple control loop to scale selected network function (more specifically, a container performing the function of UPF in 5G core network). The lab focuses on the monitoring aspect and demonstrating a simple implementation of the scaling operation. The control loop will combine monitoring and scaling. You will design it within the project that follows the lab. However, we do not use Kubernetes operator framework for that. Instead, we use an external application containing all loop logic. We expect the lab and project will provide you with a foundation for designing and implementing your own, even more advanced control loops in Kubernetes.

> [!Note]
> Using Kubernetes Operator Framework is a native approach to orchestrate resources in Kubernetes. However, the entry level to this framework is quit high and so beyond the scope of our course. Additionally, Kubernetes operators may not be the best choice for managing higher-level abstractions with a complex logic where using dedicated applications can be more appropriate.

The control loop, driven by a selected service-level metric, will operate on the resource orchestration level. It will vertically scale the UPF container in the 5G core network without recreating the pod.  Vertical scaling (in-place scaling) is beneficial for statefull services (vertical scaling in not suitable for stateful services). In Kubernetes, it is known as the so called In Place Pod Vertical Scaling (or In-Place Pod Resize). It was a relatively new feature in Kubernetes (alpha status) during the preparation of the main part of this guide. It graduated to stable in version 1.35. However, as we have not tried it so far on the ARM64 platform. For kube-prometheus compatibility reasons we are currently using K3s v1.34 and apply our older K3s installation procedure where InPlacePodVerticalScaling feature gate had to be explicitly enabled during the installation or in a running cluster. In Kubernetes 1.35, this feature gate is enabled by default and should work out of the box (no need for extra configurations). One can give it a try, the newest kube-prometheus should also work, but we have not checked that so far.
