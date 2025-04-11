Enabling InPlacePodVerticalScaling

(according to: https://github.com/k3s-io/k3s/issues/12025#issuecomment-2769290290)

1) On the server (master) node(s)

- modify file /etc/systemd/system/k3s.service to add feature-gates for apiserver, controller-manager and scheduler as follows

(Note: remaining settings visible are not relevant to in place scaling)

ubuntu@k3s01:~$ sudo nano /etc/systemd/system/k3s.service
...
ExecStart=/usr/local/bin/k3s \
    server \
        '--write-kubeconfig-mode' \
        '644' \
        '--disable' \
        'servicelb' \
        '--disable-cloud-controller' \
        '--kube-apiserver-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-controller-manager-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-scheduler-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kubelet-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-proxy-arg=feature-gates=InPlacePodVerticalScaling=true' \

- save the file and run

ubuntu@k3s01:~$ sudo systemctl daemon-reload
ubuntu@k3s01:~$ sudo systemctl stop k3s.service
ubuntu@k3s01:~$ sudo systemctl start k3s.service

2) On each agent node where the feature is to be enabled

(Note: one can enable the feature on a subset of workers, but needs to control pod placement then)

- modify file /etc/systemd/system/k3s-agent.service to add feature-gates as follows:

ubuntu@k3s02:~$ sudo nano /etc/systemd/system/k3s-agent.service
...
ExecStart=/usr/local/bin/k3s \
    agent \
        '--kubelet-arg=feature-gates=InPlacePodVerticalScaling=true' \
        '--kube-proxy-arg=feature-gates=InPlacePodVerticalScaling=true' \

- save the file and run:

ubuntu@k3s02:~$ sudo systemctl daemon-reload
ubuntu@k3s02:~$ sudo systemctl stop k3s-agent.service
ubuntu@k3s02:~$ sudo systemctl start k3s-agent.service

3) Check if in place scaling works

(if succesfull, "pod/ patched" is notified as shown below)

ubuntu@k3s01:~$ sudo kubectl patch pod open5gs-upf-dcd9db5cb-kl2jq --subresource resize --patch '{"spec":{"containers":[{"name":"open5gs-upf", "resources":{"requests":{"cpu":"50m"}, "limits":{"cpu":"110m"}}}]}}'
pod/open5gs-upf-dcd9db5cb-kl2jq patched

