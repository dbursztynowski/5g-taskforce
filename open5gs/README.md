# Contents
[Installation of Open5GS and UERANSIM](#installation-of-open5gs-and-ueransim)

[Prepare Open5GS Helm chart](#prepare-open5gs-helm-chart)

  [Download Open5GS Helm chart](#download-open5gs-helm-chart)
  [Modify Open5GS Helm chart](#modify-open5gs-helm-chart)

[Deploy Open5GS](#deploy-open5gs)

  [Remarks](#remarks)
  [Deployment](#deployment)

[Deploy UERANSIM](#deploy-ueransim)

  [Introduction](#introduction)
  [Deploying UERANSIM with initial set of UEs attached](#deploying-ueransim-with-initial-set-of-ues-attached)
  [Generating UE data plane traffic](#generating-ue-data-plane-traffic)
  [Connecting additional UEs to the network (bulk attach)](#connecting-additional-ues-to-the-network-bulk-attach)
  [Bulk disconnection (detachement) of additional connected UEs](#bulk-disconnection-detachement-of-additional-connected-ues)
  [Next steps](#next-steps)

# Installation of Open5GS and UERANSIM

This document describes how to install and run Open5GS 5G core network and UERANSIM RAN emulator using Helm charts from Gradiant on Raspberry Pi. The original reference page can be found [here](https://gradiant.github.io/5g-charts/open5gs-ueransim-gnb.html), but it cannot be used directly, as some adaptations are necessary to make the platform work on Raspberry Pi.

If you cloned this repository, it is ready to use and you can implement the entire platform (Open5GS and UERANSIM) fully customized to our needs. In this case you can skip section **Prepare Open5GS Helm chart** below and go directly to step [Deploy Open5GS](deploy-open5gs). This is the recommended approach to do the lab. However, if you are interested in the details of the modifications necessary to run the platform on Raspberry Pi, you may want to start from scratch and follow all steps beginning from [Prepare Open5GS Helm chart](prepare-open5gs-helm-chart).

The key competencies for our lab are the implementation of Open5GS and UERANSIM and the management of UEs in the network by attaching (joining the network) and detaching (leaving the network) groups of UEs. In particular, we will attach/detach UEs to trigger CPU scaling operations of the UPF (User Plane Function) in our Open5GS core network. Also also covered in this guide is traffic generation by UEs although it is not mandatory for our lab (well, `ping` command can be used to verify if all works fine on the 5G network level).

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
    Note: With the configuration given below, 20 User Equipments (UE) are registered in the core network database when the 5G core network is deployed. This registration does not set up a bearer session for the terminals, though. It only corresponds to the network provider registering 20 SIM cards (or user accounts), which subsequently will be used in nNAS (Non-Access Stratum) signalling procedures to certify the terminals attaching to the network. In fact, the mobile network operator registers user accounts in the core databases in a separate process when the accounts are created based on orders form customer services. Here, the _populate_ container is a handy add-on from Gradiant that simplifies the use of Open5GS/UERANSIM during experiments by populating user accounts in the Open5GS core network database in bulk. We do not delve into the details of UE specification, suffices it to say that strings as `999700000000001` are IMSI/SUPI nummbers and the pairs `1 111111` terminating each line denote SST (Slice Service Type) and SD (Slice Differentiator), respectively, and together they define S-NSSAI (Single Network Slice Selection Assistance Information) identifier. According to 3GPP standards, Slice Service Type "1" (SST 1) refers to Enhanced Mobile Broadband (eMBB).
    
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

## Remarks
During deploying our instance of Open5GS core network, 20 user equipments (user SIM cards/user accounts, UE) are populated in the core network data base. This setting is configured in file `5g-taskforce/open5gs/5gSA-values-enable-metrics-v228.yaml` (in the original Gradiant documentation this file is named 5gSA-values.yaml, but we changed this name to emphasize that we are using a customizewd version of the file). During the experiments, you will be able to connect as many UE devices to the network as this number.

## Deployment

### Dry run
Before deploying Open5GS yu can execute dry run to check Kubernetes manifests generated by Helm. Select _namespace_ according to your needs. If it's not default you should create one before (`kubctl create namespace <namespace>`).

```
$ helm -n <namespace> install --debug --dry-run open5gs ./open5gs-228 --version 2.2.8 --values ./5gSA-values-enable-metrics-v228.yaml
```

### Actual deployment
```
$ helm -n <namespace> install open5gs ./open5gs-228 --version 2.2.8 --values ./5gSA-values-enable-metrics-v228.yaml
```
Nothe: In what follows, we assume we are working in the _default_ namespace so we will skip the _namspace_ in `kubectl` commands.

Ypu should now wait until all pods are up and running. This may last several minutes, do not be surprised seeing various error notifications. Try this:
```
$ kubectl get pods --watch
```

Once all the pods are up and running you can step to installing and operating UERANSIM as described in the next section.

# Deploy UERANSIM

## Introduction

UERANSIM in RAN network emulator including both gNB and user equipments (terminals, UE). In Gradiant implementation each of these parts is created as a separate deployment/container (`ueransim-gnb` for gNB and `ueransim-gnb-ues` for a set of UEs). UEs are implemented in a container responsible for handling radio interface signalling procedures and bearer session to carry data plane traffic. In fact, UERANSIM handles higher layers of the signalling radio stack - Radio Resource Control (RRC) and Non-Access Stratum (NAS) layers. For the user of the UERANSIM emulator (like us or programs that can be attached) UEs are accessible in the form of TUN interfaces created in the network namespace of `ueransim-gnb-ues` Pod. One can run `exec` on the Pod to run Linux commands for created TUN interfaces and generate UE application traffic. UE application traffic in UERANSIM is handled in the protocol stack IP/SDAP/PDCP/RLC. More on application traffic generation later in this document.

In Gradiant implementation of UERANSIM, UEs can be attached to the network (and detached) in bulk using Helm commands with customized parameters. UEs attached in bulk are run (represented by their TUN interfaces) in distinct deployment/container (with unique name). While it is possible to attach UEs to the network one by one in a single deployment, we will use the bulk (multi-deployment) option in this lab because it better suits our needs and is simpler to use. More on this later.

## Deploying UERANSIM with initial set of UEs attached

Running the following command deployes UERANSIM, connects the gNB to the Open5GS core network and connects an initial set of four UEs to the network (attaching UE corresponds to what happens when you switch on your mobile device). The number of UEs to create is configured in file gnb-ues-values.yaml (currently it equals 4).
- NOTE: We create UEs in groups (bulk). From the Helm perspective, each group is implemented in a separate Helm release. From the Kubernetes perspective, the group is implemented as deployment (with respective pod and container in the pod). Below command installs Helm relase named `ueransim-gnb`. We assume deploying UERANSIM in the same namespace as Open5GS.

```
$ helm install ueransim-gnb oci://registry-1.docker.io/gradiant/ueransim-gnb --version 0.2.6 --values ./gnb-ues-values.yaml
```

Successfull installation of UERANSIM will print multiple "help" lines on the screen describing different options of using UERANSIM. After that, wait a while until both ueransin-gnb and ueransim-gnb-ues pods are up and running. You can check this running `kubectl get pods --watch`.

## Generating UE data plane traffic

This can be achieved by doing `kubectl exec` on respective pod/container. In the following example we log to container shlell and run ping command in the terminal.

Enter container shell and run ping command and curl after that:
(Note: To check for the name of the UE deployment simply run `kubectl get deployments'.)

```
$ kubectl exec -it deployment/ueransim-gnb-ues -- /bin/bash
> ping -I uesimtun0 wp.pl
...
> curl --interface uesimtun0 https://google.com
...
```

The above commands can be run without directly entering the container's shell, e.g.:
```
$ kubectl exec deployment/ueransim-gnb-ues -- /bin/bash -c "curl --interface uesimtun0 https://google.com"
```

## Connecting additional UEs to the network (bulk attach)

**sprawdzić nazwę dodatkowego deploymentu - ueransim-ues-additional czy inna? !!!!!!!!!!!!!!!!!**

Subsequent groups (bulks) of UEs can be created using Helm as distinct Helm releases as show below. 

Note 1: More groups can be created in a similar way, but the total number of connected UEs must not exceed the number of UEs declared (populated) in Open5$GS core.
Note 2: Remember that MSISDN of our UEs start from the value `0000000001`, and always keep track of the MSISDNs taken by existing UEs and free MSISDNs when the UEs get connected and disconnected from the network.
```
$ helm install ueransim-ues-additional oci://registry-1.docker.io/gradiant/ueransim-ues \
  --set gnb.hostname=ueransim-gnb --set count=5 --set initialMSISDN="0000000005"
```

In this example, we create Helm release named `ueransim-ues-additional` that will deploy a separate deployment/container implementing a group of UEs. This deployment will be named `ueransim-ues-additional`, so after its Helm release. Its UEs will be connected to the existing gNB named `ueransim-gnb` (`--set gnb.hostname=ueransim-gnb`) implemented by a deployment with the same name `ueransim-gnb`. This UE group will contain 5 additional UEs (`--set count=5`). The first of the additional UEs will be assigned MSISDN `0000000005` (`initialMSISDN="0000000005"`) and (according the population rules of the `populate` container) consecutive UEs will receive subsequent MSISDN numbers.

You can execute commands related to particular UEs (respective TUN interfaces) the same way as before for the initial set of UEs.

## Bulk disconnection (detachement) of additional connected UEs

Detaching additional connected UEs can be achieved by uninstalling respective Helm release, e.g.:

```
$ helm uninstall ueransim-ues-additional
```

This will detach all UEs emulated by the uninstalled Helm release from the network (respective deployment/pod is deleted under the hood). In a real network, it would correspond to multiple terminals undergoing network detach procedure (e.g., switching off or entering airplane mode). 

_Notice that the above uninstall command applies to a Helm release dedicated only to a group of UEs (and respective deployment/container under the hood). You should not try to adapt this command to detach in bulk the initial set of UEs (those activated together with gNB when UERANSIM was created)._

## Next steps

Having UERANSIM and Open5GS core up and running, and knowing how to manage groups of UEs, you can now proceed to service monitoring and resource scaling documented in [_looptest_](./looptest).
