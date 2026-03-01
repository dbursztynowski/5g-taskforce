## This the valid version for the SPIW lab.

# Installing and operating Open5GS and UERANSIM

## Contents
1. [Introduction](#introduction)
2. [Prepare Open5GS Helm chart](#prepare-open5gs-helm-chart)
   - [Download Open5GS Helm chart](#download-open5gs-helm-chart)
   - [Modify Open5GS Helm chart](#modify-open5gs-helm-chart)
3. [Deploy Open5GS](#deploy-open5gs)
   - [Remarks](#remarks)
   - [Deployment](#deployment)
   - [Delete Open5GS](#delete-open5gs)
4. [Deploy UERANSIM](#deploy-ueransim)
   - [Introduction](#introduction)
   - [Deploy UERANSIM with initial set of UEs attached](#deploy-ueransim-with-initial-set-of-ues-attached)
   - [Generate UE data plane traffic](#generate-ue-data-plane-traffic)
   - [Connect additional UEs to the network (bulk attach)](#connect-additional-ues-to-the-network-bulk-attach)
   - [Bulk disconnection (detachement) of additional connected UEs](#bulk-disconnection-detachement-of-additional-connected-ues)
5. [Next steps](#next-steps)

# Introduction

This document describes how to install and run Open5GS 5G core network and UERANSIM RAN emulator using Helm charts from Gradiant on Raspberry Pi. The original reference page can be found [here](https://gradiant.github.io/5g-charts/open5gs-ueransim-gnb.html), but it cannot be used directly, as some adaptations are necessary to make the platform work on ARM64/Raspberry Pi.

### NOTE: If you have cloned this repository, it is ready to use and you can implement the entire platform (Open5GS and UERANSIM) fully customized to our needs. In this case you can skip section _Prepare Open5GS Helm chart_ below and go directly to step [Deploy Open5GS](deploy-open5gs). This is the recommended approach to do the lab. However, if you are interested in the details of the modifications necessary to run the platform on Raspberry Pi, you can start from scratch and follow all the steps starting with section [Prepare Open5GS Helm chart](prepare-open5gs-helm-chart).

TThe main results of this lab are a working instance of the Open5GS and UERANSIM platform and the ability to manage UEs in the network by attaching (joining the network) and detaching (leaving the network) groups of UEs. Specifically, we will be attaching/detaching the UEs to trigger the UPF CPU scaling operation (UPF is the User Plane Function) in Open5GS core network. Also covered in this guide is traffic generation by the UEs although this skill is not mandatory to complete the lab (well, `ping` command can be used to verify if all works fine on the 5G network level).

A simplified top-level view of the 5G environment we are going to work with is shown in the figure below. There are two main part: Open5GS playing the role of 5G core network and UERANSIM being combined user equipment and RAN network emulator. Open5GS exhibits standard 3GPP interfaces (compliant with Release 17 as of this writing) and both parts interwork using standard N2 and N3 interfaces (N1 interface is only partially implemented in UERANSIM - it covers NR-RRC and NAS layers while remaining layers are emulated by proprietary Radio Link Simulation protocol not compatible with the 3GPP stack) interfaces. In the figure, we explicitly present only AMF, SMF and UPF and remaining functions of the core are represented in the figure in aggregated way (but you can list them in the cluster as Kubernetes deployments). As we will see later, each part of the platform (Open5GS, UERANSIM) can be created using Helm. User equipment groups (UE groups) in the figure correspond to groups of terminals emulated by UERANSIM, each group being implemented by a distinct Kubernetes deployment. Each group (more precisely, the container that implements the group) can be logged in to execute commands that generate user traffic (in particular ICMP/ping, HTTP/curl, Iperf). More information about the internal structure of UERANSIM that is needed for doing the lab will be presented later in this document.

<p align="center">
<img src="/figures/open5gs-ueransim-arch.jpg" alt="Open5GS/UERANSIM architecture" width="600" style="display: block; margin: 0 auto" />
</p>

# Prepare Open5GS Helm chart

#### If you cloned this repository, you are ready to go directly to step [Deploy Open5GS](deploy-open5gs). This section is for newcomers and/or users interested in customizaions required to deploy Gradiant Open5GS/UERANSIM on ARM64/Raspberry Pi.

## Download Open5GS Helm chart

This step is necessary, because we have to modify several settings to adapt the platform for Raspberry Pi.

Throughout this document, it is assumed `open5gs` is the the name of the leaf directory on the working directory path.

```
$ helm pull oci://registry-1.docker.io/gradiantcharts/open5gs --version 2.2.8
$ mkdir open5gs-228
$ tar -xvzf open5gs-2.2.8.tgz -C ./open5gs-228
```

## Modify Open5GS Helm chart

Chart modifications cover three following areas:

- customize containers `mongod`, `webui` and `populate` to run on Raspberry Pi
- create extended set of UE when deploying the platform (container `populate`)
- enable Prometheus metric exporters in AMF, SMF, UPF and PCF containers (containers `amf`, `upf`, `smf`, `pcf`)

### Modify the charts for mongodb, webui and populate

We use custom image of mongodb container able to run on Raspberry Pi. Another option is to use origunal images, but they would have to be quite old (i.e., versions 4.x while latest mongodb versions come form the range 8.x). 

- Currently (May 2025) the following changes for mongodb, webui and populate apply:
  Note: configuration files are specified using YAML, so pay attention to leading spaces if you modify your files by typing the updates directly.
  
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
    Note: With the configuration given below, 20 User Equipments (UE) are registered in the core network database when the 5G core network is deployed. This registration does not set up a bearer session for the terminals, though. It only corresponds to the network provider registering 20 SIM cards (or user accounts), which subsequently will be used in nNAS (Non-Access Stratum) signalling procedures to certify the terminals attaching to the network. In fact, the mobile network operator registers user accounts in the core databases in a separate process when the accounts are created based on orders form customer services. Here, the _populate_ container is a handy add-on from Gradiant that simplifies the use of Open5GS/UERANSIM during experiments by populating user accounts in the Open5GS core network database in bulk. We do not delve into the details of UE specification, suffices it to say that strings as `999700000000001` are IMSI/SUPI numbers and the pairs `1 111111` terminating each line denote SST (Slice Service Type) and SD (Slice Differentiator), respectively, and together they define S-NSSAI (Single Network Slice Selection Assistance Information) identifier. According to 3GPP standards, Slice Service Type "1" (SST 1) refers to Enhanced Mobile Broadband (eMBB).
    
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

As stated before, it is assumed `open5gs` is the the name of the leaf directory on the working directory path.

## Deployment

### Dry run
Before deploying Open5GS you can execute `dry run` to check Kubernetes manifests generated by Helm. Select the _namespace_ according to your environment. If it's not default you should create one before (`kubctl create namespace <namespace>`).

```
$ helm -n <namespace> install --debug --dry-run open5gs ./open5gs-228 --version 2.2.8 --values ./5gSA-values-enable-metrics-v228.yaml
```

### Actual deployment

Open5GS is deployed in the form of Helm `release`. Below, the release is created in namespace `<namespace>` and is given the name `open5gs` (`helm -n <namespace> install open5gs').

```
$ helm -n <namespace> install open5gs ./open5gs-228 --version 2.2.8 --values ./5gSA-values-enable-metrics-v228.yaml
```
Nothe: In what follows, we assume we are working in the _default_ namespace so we will skip the _namspace_ in `kubectl` commands.

Ypu should now wait until all pods are up and running. This may last several minutes, so do not be surprised seeing various error notifications. Try this:
```
$ kubectl get pods --watch
```

Once all the pods are up and running (their status should be `1/1 Running`) you can step to installing and operating UERANSIM as described in the next section.

### Delete Open5GS

Deletion of Open5GS is done by uninstalling/deleting respective Helm release, e.g.:
```
$ helm uninstall open5gs
```

# Deploy UERANSIM

## Introduction

UERANSIM in RAN network emulator including both gNB and user equipments (terminals, UE). In Gradiant implementation each of these parts is created as a separate deployment/container (`ueransim-gnb` for gNB and `ueransim-gnb-ues` for a set of UEs). UEs are implemented in a container responsible for handling radio interface signalling procedures and bearer session to carry data plane traffic. In fact, UERANSIM handles higher layers of the signalling radio stack - Radio Resource Control (RRC) and Non-Access Stratum (NAS) layers (upper RAN stack). For the user of the UERANSIM emulator (like us or programs that can be attached) UEs are accessible in the form of TUN interfaces created in the network namespace of `ueransim-gnb-ues` Pod. One can run `exec` on the Pod to run Linux commands for created TUN interfaces and generate UE application traffic. UE application traffic in UERANSIM is handled in the protocol stack IP/SDAP/PDCP/RLC. More information on generating traffic in applications will be presented later in the document.

In the Gradiant implementation of UERANSIM, UEs can be attached to the network (and detached from it) in bulk using Helm commands with customized parameters. UEs attached in bulk are run (being represented by respective TUN interfaces) in distinct deployment/container (with a unique name). While it is possible to attach UEs to the network one by one (single-deployment), we will use the bulk (multi-deployment) option in this lab because it better suits our needs and is simpler to use. More on this later.

## Deploy UERANSIM with initial set of UEs attached

Running the following command deployes UERANSIM, connects the gNB to the Open5GS core network and connects an initial set of four UEs to the network (attaching UE corresponds to what happens when you switch on your mobile device). The number of UEs to create is configured in file gnb-ues-values.yaml (currently it equals 4).
- NOTE: We create UEs in groups (bulk). From the Helm perspective, each group is implemented in a separate Helm release. From the Kubernetes perspective, the group is implemented as deployment (with respective pod and container in the pod). Below command installs Helm relase named `ueransim-gnb` (in the default namespace in this example). UERANSIM should be deployed in the same namespace as Open5GS.

```
$ helm install ueransim-gnb oci://registry-1.docker.io/gradiant/ueransim-gnb --version 0.2.6 --values ./gnb-ues-values.yaml
```

After successful installation of UERANSIM, multiple "help" lines will appear on the screen describing the different options for using UERANSIM. After that, wait a while until both `ueransin-gnb` and `ueransim-gnb-ues` pods are up and running. You can check this with the command `kubectl get pods --watch`.

The structure of our UERANSIM component is depicted in the figure below. On its right-hand side, Pod `gnb` handles full-fledged GTP-U tunnels of respective PDU sessions. Between Pod `gnb` and each Pod `ues`, data radio bearers (actually, only their upper layer protocols) of respective PDU sessions are handled. There is one deployment/pod performing the functions of gNB and there can be several deployments/pods each emulating a subset of UEs - user mobile devices. Each UE is represented in the Pod `ues` as TUN interface with the name uesimtun0, ueasimtun1, etc. Common Linux commands (ping, curl, ...) can be applied to these interfaces to generate/receive traffic to/from the ouside of our 5G core network (e.g., to the Internet if our infrastructure provides such connectivity). Our initial setup contains the gNB deployment named `ueransim-gnb` and one UE deployment named `ueransim-gnb-ues`, the latter hosting a group of four UEs. More UEs can be attached to the network. Later on we will use perhaps the simplest option relying on the creation of additional UE deployment(s) with the use of Helm `install` command to create Helm `release` that deploys a separate (new) Pod `ues` implementing the set of new UEs. Each such additional UE deployment can host several UEs, the number of which is specified as a parameter in the create command. Additional `ues` deployments (each created within Helm `release` with a unique name) can be added and deleted thus allowing us to easily modify the number of UEs attached to the network. In the figure below, one additional UE deployment is shown with the name `ueransim-ues-additional` (though it is not present after initial installation).

<p align="center">
<img src="/figures/ueransim-arch.jpg" alt="UERANSIM architecture and UE deployments" width="600" style="display: block; margin: 0 auto" />
</p>

To delete this initial configuration of UERANSIM uninstall its Helm release:
```
$ helm uninstall ueransim-gnb
```

## Generate UE data plane traffic

This can be achieved by performing respective commands in selected `uearansin-gnb-uesX` container. In the following example we log to a container shell and run commands in the terminal.

Enter container shell and run ping command and curl after that:
(Note: To check for the name of the UE deployment simply run `kubectl get deployments`.)

```
$ kubectl exec -it deployment/ueransim-gnb-ues -- /bin/bash
> ping -I uesimtun0 wp.pl
...
> # with curl, use the flag --interface, not -I
> curl -k --interface uesimtun0 https://pw.ed.pl
...
```

The above commands can be run without directly entering the container shell (no `-it` option in the command), e.g.:
```
$ kubectl exec deployment/ueransim-gnb-ues -- /bin/bash -c "curl -k --interface uesimtun0 https://pw.edu.pl"
```

You can also run Iperf to generate higher volume traffic for performance-oriented tests. UERANSIM provides utility `nr-binder` dedicated to bind `uesimtunX` interface to almost any application and allow this application to exchange traffic over the 5G network. To this end it is necessary to perform a couple of steps as specified below.

* enter the shell respective `ueransim-gnb-uesX` container and change the permissions of the `nr-binder` executable (to be done once in a given `ueransim-gnb-uesX` Pod)
```
$ kubectl exec -it deployment/ueransim-gnb-ues -- /bin/bash
root@ueransim-gnb-ues-5bdfb48dc9-m24rp:~# cd /usr/local/bin
root@ueransim-gnb-ues-5bdfb48dc9-m24rp:/usr/local/bin# chmod g+x nr-binder
```

* using Iperf in client mode
  - below, we use a public Iperf server (it may happen to be busy on a given port, then try another port or server)
  - the list of public Iperf servers: https://iperf.fr/iperf-servers.php
  - you can install Ipefr server in your cluster, and even set link metrics as delay or bandwidth using the tc utility
  - example docker image with Iperf: https://hub.docker.com/r/networkstatic/iperf3
```
# unsuccessful run (server busy)
root@ueransim-gnb-ues-5bdfb48dc9-m24rp:/usr/local/bin# ./nr-binder 10.45.0.5 iperf3 -c speedtest.serverius.net -i 1 -t 20 -p 5002
iperf3: error - the server is busy running a test. try again later

# successful run (another server)
root@ueransim-gnb-ues-5bdfb48dc9-m24rp:/usr/local/bin# ./nr-binder 10.45.0.5 iperf3 -c paris.bbr.iperf.bytel.fr -i 1 -t 20 -p 9239
Connecting to host paris.bbr.iperf.bytel.fr, port 9239
[  5] local 10.45.0.5 port 54847 connected to 5.51.3.41 port 9239
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  4.75 MBytes  39.8 Mbits/sec  313    112 KBytes
...
```

* using curl (use the flag --interface, not -I, and enter the IP address of the interface)
```
root@ueransim-gnb-ues-5bdfb48dc9-m24rp:/usr/local/bin# ./nr-binder 10.45.0.5 curl -k https://pw.edu.pl
```

Notice there are also other UERANSIM tools available in `ueransim-gnb-ues` Pod in directory `/usr/local/bin`. A short guide how to use them is available [here](https://github.com/aligungr/UERANSIM/wiki/Usage).

## Connect additional UEs to the network (bulk attach)

Subsequent groups (bulks) of UEs can be created in the form of distinct Helm releases as shown below. 

- Note 1: More groups can be created in a similar way, but the total number of connected UEs must not exceed the number of UEs declared (populated) in Open5$GS core (20 if you used our template of container _populate_ shown in this [section](#modifications-in-mongodb-webui-and-populate-charts)).
- Note 2: Remember that MSISDN of our UEs start from the value `0000000001`, and always keep track of the MSISDNs taken by existing UEs and free MSISDNs when the UEs get connected and disconnected from the network.
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

This will detach all UEs emulated by the uninstalled Helm release from the network (respective deployment/pod is deleted under the hood). In a real network, it would correspond to multiple terminals undergoing network detach procedure (e.g., switching off or entering airplane mode). This procedure does not have impact on the initial setup so gNB and the initial group of UEs remain intact.

## Next steps

With UERANSIM and the Open5GS core up and running, and the knowledge of UE group management, you can move on to service monitoring and resource scaling, as documented in [_looptest_](../looptest).
