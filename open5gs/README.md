# Installation of Open5GS and UERANSIM

This document describes how to install Open5GS 5G core network and UERANSIM RAN emulator using Helm charts form Gradiant. Reference page can be accessed [here](https://gradiant.github.io/5g-charts/open5gs-ueransim-gnb.html), but we make several adaptations to enable the platform run on Raspberry Pi.

Actually, if you have cloned this repository than it is ready to deploy the paltform without any modifications. In such a case you can directly go to step [Deploy Open5GS](deploy-open5gs). However, if you are interested in the details of the modifications necessary to run the platform on Raspberry Pi, you can start from scratch and follow the steps beginning from [Prepare Open5GS Helm chart](prepare-open5gs-helm-chart).

# Prepare Open5GS Helm chart

## Download Open5GS Helm chart

This step is necessary to adapt the platform for Raspberry Pi.

```
$ helm pull oci://registry-1.docker.io/gradiantcharts/open5gs --version 2.2.8
$ mkdir open5gs-228
$ tar -xvzf open5gs-2.2.8.tgz -C ./open5gs-228
```

## Modify Open5GS Helm chart

# Deploy Open5GS

