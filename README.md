# Setup Kubernetes Nodes
This setup was tested on AWS EC2 instances with ubuntu

## 1. Pre-Reqs on all Nodes
Use k8s_pre-req-script.sh and jump to Step-2 (On K8S Master)

### Setup Hostname
```
sudo hostnamectl set-hostname "master.example.net"
```
or in workers
```
sudo hostnamectl set-hostname "node1.example.net" 
```
To hostnames to take effect
```
exec bash
```

### Disable Swap & Add kernal Params

Swap off
```
sudo swapoff -a

sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

Load kernel modules
```
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay

sudo modprobe br_netfilter
```

Params for k8s
```
sudo tee /etc/sysctl.d/kubernetes.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT
```

Reload changes
```
sysctl --system
```

### Install Containerd Runtime (Like Docker)

Install Dependencies
```
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
```

Enable Docker Repo
```
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

Install Containerd
```
sudo apt update

sudo apt install -y containerd.io
```

Configure containerd so that it starts using systemd as cgroup.
```
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1

sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
```

Restart and enable containerd service
```
sudo systemctl restart containerd

sudo systemctl enable containerd
```

### Add Repo of K8S & Install kubectl, kubeadm & kubelet

Download public key
```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Add K8S apt repo
```
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Install kubectl, kubeadm & kubelet and Mark hold to prevent changes
```
sudo apt update

sudo apt install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl
```

Install fish shell (Optional)
```
sudo apt-add-repository -y ppa:fish-shell/release-3

sudo apt update

sudo apt install fish

```

## 2. On K8S Master

### Update /etc/hosts file in Master & each node
```
10.193.164.247 master.example.net master
10.193.164.196 node1.example.net node1
10.193.164.62 node2.example.net node2
```

### Run kubeadm command

Initialize Master
```
sudo kubeadm init --control-plane-endpoint=master.example.net
```

or to regenerate token for works
```
kubeadm token create --print-join-command
```

Note the output to use in worker-nodes to join this cluster
```
kubeadm join master.example.net:6443 --token xxx \
        --discovery-token-ca-cert-hash xxxx 
```


### Configure master node

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Check kubectl
```
kubectl cluster-info
kubectl get nodes
```

## 3. On K8S Worker Nodes
### Configure worker ndoe
```
kubeadm join master.example.net:6443 --token xxx \
        --discovery-token-ca-cert-hash xxxx 
```
Check Status
```
kubectl get nodes
```

## 4. Install Network Plugin 
Install Network Plugin using kubectl (usually from master)
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
```

## 5. Install Kubernetes Dashboard
Install K8S Dashboard
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

Allow external use via NodePort (change ClusterIP to NodePort and add a nodePort param from below command)
```
kubectl edit service/kubernetes-dashboard -n kubernetes-dashboard
```

Create Dash-Admin user using k8s_dash_admin-user.yaml file

# Other Commands
Set FISH as default shell
```
sudo chsh -s /usr/bin/fish
```

Enable Pods to be deployed on Master
```
kubectl taint node <master-node> node-role.kubernetes.io/control-plane:NoSchedule-
```

Token Create 
(alternatively use admin-user-dash-k8s.yaml)
```
kubectl -n kubernetes-dashboard create token admin-user
```

Token Retrieve: 
```
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```

# Refs
K8S Dashboard Users: https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md

K8S dashboard: https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

K8S dashboard external access: https://k21academy.com/docker-kubernetes/kubernetes-dashboard/

K8S Setup: https://www.linuxtechi.com/install-kubernetes-on-ubuntu-22-04/