Below, k3s cluster is installed.
For k8s cluster on multinode see, e.g., https://phoenixnap.com/kb/install-kubernetes-on-ubuntu

*****************************************
*****************************************
PREPARE UBUNTU 22.04

=========================================
if OpenStack (optional)
=========================================
- to lunch instance from image with password authentication enabled (here pwd=ubuntu)
  - insert the following into Configuration/Customization script pane in OpenStack Dashboard
    ubuntu is the default user on Ubuntu 
#cloud-config
password: ubuntu
chpasswd: { expire: False }
ssh_pwauth: True

- more on this: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux_atomic_host/7/html/installation_and_configuration_guide/setting_up_cloud_init#setting_up_cloud_init

- add a rule(s) to a security group assigned to your OpenStack servers accepting all desired traffic
  (in a non-production environment one can allow all traffic setting the following arguments of the rule:
   Rule: other protocol
   IP protocol: -1
   Remote: CIDR
   CIDR: 0.0.0.0/0
  )

=========================================
for VirtualBox only
=========================================
- enable terminal
  https://www.youtube.com/watch?v=NvTMQBxGqDw
Settings -> Region and language -> change Language=English(UK) -> Reboot

- add user to the sudo group
$ su -
# sudo usermod -aG sudo <username>
# visudo ==> add:
  <username> ALL=(ALL) NOPASSWD:ALL
# exit

- disable Wayland (if you experience problems with the display)
https://linuxconfig.org/how-to-enable-disable-wayland-on-ubuntu-22-04-desktop
$ sudo nano /etc/gdm3/custom.conf
  WaylandEnable=false
$ sudo systemctl restart gdm3

- enable VBoxGuestAdditions
VM -> Devices -> Mount image with Guest Additions -> cd /media/ubuntu/VBox_GAs_xyz (xyz according to your env) -> 
   sudo VBoxLinuxAdditions.run -> VM

Prepare reamining stuff (all releases)
=========================================

- enable IP forwarding
  https://linuxconfig.org/how-to-turn-on-off-ip-forwarding-in-linux <== also torubleshooting
  check if required
$ sudo sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 0   => required if 0
$ sudo nano /etc/sysctl.conf
  net.ipv4.ip_forward = 1
$ sudo sysctl -p

$ sudo apt update
$ sudo apt upgrade

$ sudo apt install git

- for any case (e.g., to use scp to copy files) checkt this - enable PasswordAuthentication
$ sudo nano /etc/ssh/sshd_config
  PasswordAuthentication yes
$ sudo service ssh restart

*****************************************
*****************************************
INSTALL KUBERNETES WITH FLANNEL

Basically, according to this: https://docs.k3s.io/quick-start with additional --cluster-cidr=..., --kube-apiserver-arg=feature-gates=... and --tls-san=... .

---

- install on master (control) node
Note: to enable external access to the API (e.g., to use kubectl) when server IP address visible externally as <floating-ip-address> is different than server IP address valid within the cluster (e.g., when the server is exposed by floating IP in OpenStack) then additional option --tls-san=<floating-ip-address> should be included in the part INSTALL_K3S_EXEC="...". This will make x509 certificate for this address become valid. For example:
$ curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--cluster-cidr=10.42.0.0/16  --kube-apiserver-arg=feature-gates=InPlacePodVerticalScaling=true --tls-san=<external-master-ip-address>" sh -

- on OpenStack VMs (allow non-critical workloads on controller)
  remove {{ }}
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION={{ v1.32.1+k3s1 }} INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --disable servicelb --disable-cloud-controller --kube-apiserver-arg=feature-gates=InPlacePodVerticalScaling=true" sh -

- when taintig controller for only critical workloads
  remove {{ }}
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION={{ v1.32.1+k3s1 }} INSTALL_K3S_EXEC="server --node-taint CriticalAddonsOnly=true:NoExecute --write-kubeconfig-mode 644 --disable servicelb --disable-cloud-controller --kube-apiserver-arg=feature-gates=InPlacePodVerticalScaling=true" sh -

  ref. https://github.com/k3s-io/k3s/issues/1381#issuecomment-582013411
       https://docs.k3s.io/installation/configuration#registration-options-for-the-k3s-server

- check status
$ systemctl status k3s.service

- copy k3s.yaml to ~HOME/.kube/config and change ownership for current user
  Note: adjust nodes / copy FROM master TO management node
$ sudo cp -i /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

---

- install agent(s)

  on master - copy node-token file with authorization token to worker (agent) node
$ sudo scp /var/lib/rancher/k3s/server/node-token ubuntu@<agent-node-address>:/home/ubuntu/node-token

  on worker (agent)
$ curl -sfL https://get.k3s.io | K3S_URL=https://<serverip>:6443 K3S_TOKEN=$(cat node-token) sh -

  where K3S_TOKEN=$(cat node-token) is stored in /var/lib/rancher/k3s/server/node-token file in the main Node and should first be
  copied onto agent node to the working directory for curl command, e.g. /home/ubuntu/node-token as in the 'sudo scp ...' command
  shown above (or one can copy-paste the token from the file directly into the command)

- check status
$ systemctl status k3s-agent

- one can additionally assign label to the agent node(s) to mark their node-role as worker, e.g.:
$ kubectl label nodes k3s02 node-role.kubernetes.io/worker=true

********************************
- uninstall k3s server: run on server
$ /usr/local/bin/k3s-uninstall.sh

- uninstall k3s agents: run on agents
$ /usr/local/bin/k3s-agent-uninstall.sh

********************************
********************************
HELM
- install helm on the management node
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh

********************************
********************************
Install kubectl
- using binaries
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux
https://greenwebpage.com/community/how-to-install-kubectl-on-ubuntu-24-04/#Method-3:-Installing-Kubectl-on-Ubuntu-24.04-Using-Kubectl-Binary-File

- installation of stable release
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
should print: kubectl: OK
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
- check installation
kubectl version --client
kubectl get nodes

********************************

$ /usr/local/bin/k3s-uninstall.sh

*********************************
INSTALL LONGHORN
- according to this
https://longhorn.io/docs/1.8.1/deploy/install/install-with-kubectl/

---------------------------------
- check the compatibility from the management node

$ curl -O https://raw.githubusercontent.com/longhorn/longhorn/refs/tags/v1.8.1/scripts/environment_check.sh
$ ./environment_check.sh

- enable missing parts on master and worker nodes
$ sudo lsmod|grep iscsi
$ sudo modprobe iscsi_tcp
$ sudo apt install nfs-common

- check again
$ ./environment_check.sh
- in case of WARNING "multipathd is running on k3s2 known to have a breakage that affects Longhorn.  See des                      cription and solution at https://longhorn.io/kb/troubleshooting-volume-with-multipath" do this
https://longhorn.io/kb/troubleshooting-volume-with-multipath/

- on the master and workers do:
$ sudo nano /etc/multipath.conf
add this et the end and save:
blacklist {
    devnode "^sd[a-z0-9]+"
}
$ sudo systemctl restart multipathd.service
- confirm updating (devnode "^sd[a-z0-9]+" should be added at the beginning of the blacklist)
$ sudo multipath -t
  Note: the symbol "!^" in response to "sudo mutlipath -t" means "all except" (see https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html-single/configuring_device_mapper_multipath/index#disabling-multipathing-by-device-name_preventing-devices-from-multipathing)

---------------------------------
- installation from the management node
$ kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.8.1/deploy/longhorn.yaml
- checking all is fine
$ kubectl -n longhorn-system get pod

*********************************
*********************************
OTHER HINTS

- remove k3s.service completely
$ sudo systemctl stop k3s.service
$ sudo systemctl status k3s.service
$ sudo systemctl disable k3s.service
$ sudo rm /etc/systemd/system/*k3s.service
$ sudo rm /usr/lib/systemd/system/*k3s.service
$ sudo systemctl daemon-reload
