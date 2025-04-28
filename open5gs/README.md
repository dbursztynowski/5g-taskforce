# Installation of Open5GS and UERANSIM

This document describes how to install Open5GS 5G core network and UERANSIM RAN emulator using Helm charts form Gradiant. Reference page can be accessed [here](https://gradiant.github.io/5g-charts/open5gs-ueransim-gnb.html), but we make several adaptations to enable the platform run on Raspberry Pi.


$ helm pull oci://registry-1.docker.io/gradiantcharts/open5gs --version 2.2.8
    
  - unzip to directory ./open5gs (https://phoenixnap.com/kb/extract-tar-gz-files-linux-command-line)
$ tar -xvzf open5gs-2.2.5.tgz -C ./open5gs-225   # adjust *.tgz file name according to your case
or
$ tar -xvzf open5gs-2.2.8.tgz -C ./open5gs-228
