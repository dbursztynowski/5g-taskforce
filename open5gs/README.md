# Installation of Open5GS and UERANSIM

This document describes how to install and run Open5GS 5G core network and UERANSIM RAN emulator using Helm charts from Gradiant on Raspberry Pi. The original reference page can be found [here](https://gradiant.github.io/5g-charts/open5gs-ueransim-gnb.html), but it cannot be used directly, as some adaptations are necessary to make the platform work on Raspberry Pi.

If you cloned this repository, it is ready to use and you can implement the entire platform (Open5GS and UERANSIM) fully customized to our needs. In this case you can go directly to step [Deploy Open5GS](deploy-open5gs). However, if you are interested in the details of the modifications necessary to run the platform on Raspberry Pi, you may want to start from scratch and follow the steps beginning from [Prepare Open5GS Helm chart](prepare-open5gs-helm-chart).

# Prepare Open5GS Helm chart

## Download Open5GS Helm chart

This step is necessary, because we have to modify several settings to adapt the platform for Raspberry Pi.

```
$ helm pull oci://registry-1.docker.io/gradiantcharts/open5gs --version 2.2.8
$ mkdir open5gs-228
$ tar -xvzf open5gs-2.2.8.tgz -C ./open5gs-228
```

## Modify Open5GS Helm chart



# Deploy Open5GS

