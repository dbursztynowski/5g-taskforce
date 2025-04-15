### 5G network based on Gradiant Helm charts for UERANSIM+Open5GS in a Raspberry Pi K3s cluster

# Contents of the repo

- Directory _open5gs_: instructions and Helm charts to install and run 5g network on RPi cluster
- Directory _looptest_: examples of reading Open5GS monitoring information from Prometheus

# How to navigate

The basic part is contained in directory [open5gs](./open5gs). It is assumed that you have your k3s deployment using Raspberry Pi 4 or 5 cluster up an running, including a monitoring package based on the [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) project. K3s installation is described in repository [k3s-taskforce\](https://github.com/dbursztynowski/k3s-taskforce). Therefore, the content of open5gs directory covers only the installation and very basic operation of our 5G environment. Refer to the [README](...) file therein for remaining instructions.

Having installed 5G network according to the descriptions in open5gs directory, you can start monitoring and managing 5G core network according to guidelines provided in directory [looptest](./looptest). Actually, our focus is to show how selected service-level metrics of the Open5GS core network can be monitored and used to organize a simple control loop. The loop will vertically scale the UPF container of the 5G core. One can then extend this example to design and implement more sophisticated control loops. IMPORTANT: Before starting, **read the [README](...) in the looptest directory and update your k3s cluster nodes** as described therein to enable vertical scaling.

