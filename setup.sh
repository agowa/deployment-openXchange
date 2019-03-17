#!/bin/bash

apt update
apt upgrade -y
apt dist-upgrade -y
apt install -y apt-transport-https ca-certificates curl software-properties-common make

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce docker-compose 
systemctl enable --now docker.service

# Install minikube
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64   && chmod +x minikube
cp minikube /usr/local/bin && rm minikube

# Install mariadb
apt-get update
apt-get install -y mariadb-server

# Configure mariadb
sed -ie 's/bind-address.*/bind-address = 0.0.0.0/gm' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb.service
mariadb -e 'CREATE DATABASE oxdata;'
mariadb -e 'GRANT ALL PRIVILEGES ON `oxdata`.* TO "openxchange"@"%" IDENTIFIED BY "mysecret2";'
mariadb -e 'GRANT ALL PRIVILEGES ON `oxdatabase_5`.* TO "openxchange"@"%" IDENTIFIED BY "mysecret2";'
mariadb -e 'FLUSH PRIVILEGES;'
# Set hostname
echo db00 > /etc/hostname
hostname db00

# Start minikube
minikube start --vm-driver=none

# Cleanup
apt autoremove -y
apt autoclean -y

# Install Open-Xchange
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
kubectl create namespace worker
kubectl create secret generic --namespace=worker --from-literal=ox-admin-password=mysecret1 ox-admin-password
kubectl create secret generic --namespace=worker --from-literal=ox-db-password=mysecret1 ox-db-password
kubectl create secret generic --namespace=worker --from-literal=ox-master-password=mysecret1 ox-master-password
mkdir -p /var/lib/docker/k8s-volumes/share
mkdir -p /var/lib/docker/k8s-volumes/admin

OX_ETC_READONLY=false make docs
