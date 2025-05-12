# Installation of Open5GS and UERANSIM

This document describes how to install and run Open5GS 5G core network and UERANSIM RAN emulator using Helm charts from Gradiant on Raspberry Pi. The original reference page can be found [here](https://gradiant.github.io/5g-charts/open5gs-ueransim-gnb.html), but it cannot be used directly, as some adaptations are necessary to make the platform work on Raspberry Pi.

If you cloned this repository, it is ready to use and you can implement the entire platform (Open5GS and UERANSIM) fully customized to our needs. In this case you can skip section **Prepare Open5GS Helm chart** below and go directly to step [Deploy Open5GS](deploy-open5gs). However, if you are interested in the details of the modifications necessary to run the platform on Raspberry Pi, you may want to start from scratch and follow all steps beginning from [Prepare Open5GS Helm chart](prepare-open5gs-helm-chart).

# Prepare Open5GS Helm chart

## Download Open5GS Helm chart

This step is necessary, because we have to modify several settings to adapt the platform for Raspberry Pi.

```
$ helm pull oci://registry-1.docker.io/gradiantcharts/open5gs --version 2.2.8
$ mkdir open5gs-228
$ tar -xvzf open5gs-2.2.8.tgz -C ./open5gs-228
```

## Modify Open5GS Helm chart

Chart modifications cover three following areas:

- enable containers mongod, webui and populate run on Raspberry Pi
- create extended set of UE when deploying the platform (container populate)
- enable Prometheus metric exporters in AMF, SMF, UPF and PCF containers (containers amf, upf, smf, pcf)

### Modifications in mongodb, webui and populate charts

We use custom image of mongodb container able to run on Raspberry Pi. Another option is to use origunal images, but they would have to be quite old (i.e., versions 4.x while latest mongodb versions come form the range 8.x). 

- Currently (April 2025) the following changes for mongodb, webui and populate apply:
  
  - in file `5gc/open5gs/open5gs-228/charts/mongodb/values.yaml`, line ~105, set
    
    ```
      image:
        registry: docker.io
        repository: dburszty/mongodb-raspberrypi
        tag: 7.0.14
    ```
    
  -  in file `5gc/open5gs/open5gs-228/charts/mongodb/values.yaml`, line ~503
    
     ```
       containerSecurityContext:
         enabled: false
     ```
     
  - in file `5gc/open5gs/open5gs-228/charts/mongodb/values.yaml` disable the liveness-, readfiness- and startup- probes (line ~544)
  
    ```
      livenessProbe:
        enabled: false
      readinessProbe:
        enabled: false  
      startupProbe:
        enabled: false
    ```
    
  - in file `5gc/open5gs/open5gs-228/charts/open5gs-webui/templates/deployment.yaml` set
  
    ```
      initContainers:
        - name: init
          # image updated to the latest tested working version for Raspberry Pi 4/5
          image: dburszty/mongodb-raspberrypi:7.0.14
    ```
    
  - in file `5g-taskforce/open5gs/open5gs-228/values.yaml` set
  
    ```
      populate:
        enabled: true
        image:
          registry: docker.io
          repository: gradiant/open5gs-dbctl
      ## DB    tag: 0.10.3  <== works only for linux/AMD64
          tag: 0.10.2
    ```

# Deploy Open5GS

