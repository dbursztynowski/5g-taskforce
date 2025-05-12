# Installation of Open5GS and UERANSIM

This document describes how to install and run Open5GS 5G core network and UERANSIM RAN emulator using Helm charts from Gradiant on Raspberry Pi. The original reference page can be found [here](https://gradiant.github.io/5g-charts/open5gs-ueransim-gnb.html), but it cannot be used directly, as some adaptations are necessary to make the platform work on Raspberry Pi.

If you cloned this repository, it is ready to use and you can implement the entire platform (Open5GS and UERANSIM) fully customized to our needs. . In this case you can skip section **Prepare Open5GS Helm chart** below and go directly to step [Deploy Open5GS](deploy-open5gs). This is the recommended approach to do the lab. However, if you are interested in the details of the modifications necessary to run the platform on Raspberry Pi, you may want to start from scratch and follow all steps beginning from [Prepare Open5GS Helm chart](prepare-open5gs-helm-chart).

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
  Note: the configuratiuon file are specified using YAML so watch the leading blanks if you modify the files yourself.
  
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
    
  - in file `5g-taskforce/open5gs/5gSA-values-enable-metrics-v228.yaml` set
    Note: With the configuration given below, 20 User Equipments (UE) are registered in the core network database when the 5G core network is deployed. This registration does not set up a bearer session for the terminals, though. It only corresponds to the network provider registering 20 SIM cards (or user accounts), which subsequently will be used in nNAS (Non-Access Stratum) signalling procedures to certify the terminals attaching to the network. In fact, the mobile network operator registers user accounts in the core databases in a separate process when the accounts are created based on orders form customer services. Here, the _populate_ container is a handy add-on from Gradiant that simplifies the use of Open5GS/UERANSIM during experiments by populating user accounts in the Open5GS core network database in bulk.
    
```
populate:
  enabled: true
  image:
    registry: docker.io
    repository: gradiant/open5gs-dbctl
    ## DB tag: 0.10.3  <== original Gradiant, works only for linux/AMD64
    tag: 0.10.2
    pullPolicy: IfNotPresent
  initCommands:
  # example of initCommands:
  #  - open5gs-dbctl add 999700000000001 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA
  #  - open5gs-dbctl add_ue_with_apn 999700000000002 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet
  #  - open5gs-dbctl add_ue_with_slice 999700000000003 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000001 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000002 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000003 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000004 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000005 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000006 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000007 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000008 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000009 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000010 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000011 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000012 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000013 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000014 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000015 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000016 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000017 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000018 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000019 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
  - open5gs-dbctl add_ue_with_slice 999700000000020 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA internet 1 111111
```

# Deploy Open5GS

During deploying our instance of Open5GS core network, 20 user equipments (user SIM cards/user accounts, UE) are populated in the core network data base. This setting is configured in file `5g-taskforce/open5gs/5gSA-values-enable-metrics-v228.yaml` (in the original Gradiant documentation this file is named 5gSA-values.yaml, but we changed this name to emphasize that we are using a customizewd version of the file). During experientation, you will be allowed to attach to the network as many UEs as this number.
