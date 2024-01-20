#RUN AS ADMIN
apt update && apt upgrade -y
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt install linux-image-extra-virtual ca-certificates curl software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
stable"

apt update

#Install docker & kubernetes
apt install docker-ce kubelet kubeadm kubectl kubernetes-cni -y

#KUBEADM INIT (1 of the 3)
#BARE METAL
#kubeadm init --pod-network-cidr 192.168.0.0/16 --service-cidr 10.96.0.0/12 --service-dns-domain "k8s" --apiserver-advertise-address $(ifconfig eth0 | grep 'inet addr'| cut -d':' -f2 | awk '{print $1}')

#OPENSTACK
#kubeadm init --pod-network-cidr 192.168.0.0/16 --service-cidr 10.96.0.0/12 --service-dns-domain "k8s" --apiserver-advertise-address $(ifconfig ens3 | grep 'inet'| cut -d':' -f2 | awk '{print $2}')

#GOOGLE CLOUD
kubeadm init --pod-network-cidr 192.168.0.0/16 --service-cidr 10.96.0.0/12 --service-dns-domain "k8s" --apiserver-advertise-address $(ifconfig ens4 | grep 'inet'| cut -d':' -f2 | awk '{print $2}')
