# Install kubectl on control nodes
# ubuntu
sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

#centos,rhel
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubectl

# Installing helm
sudo snap install helm --classic

# a nice example to deploy k8s using ansible and vagrant
# https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/

kubectl -n kube-system get secret jenkins-token-q62zg --template={{.data.token}} | base64 -d

## Installing glusterfs
sudo add-apt-repository ppa:gluster/glusterfs-7
sudo apt-get install glusterfs-server
sudo mkdir -p /export/gluster
# using force to be allowed to create the volume in root partition
sudo gluster volume create data1 192.168.100.3:/export/gluster/data1 force
sudo gluster volume start data1

# Create kubernetes endpoint for glusterfs
## Create endpoints
#---------------------------------------------------
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: glusterfs
  namespace: build
  labels:
    ep: gluster
spec:
  ports:
  - port: 1729
---
apiVersion: v1
kind: Endpoints
metadata:
  name: glusterfs
  namespace: build
  labels:
    ep: gluster
subsets:
  - addresses:
      - ip: 192.168.100.3
    ports:
      - port: 1729
EOF

## Create persistent volumes
cat <<EOF | kubectl apply -f -
kind: PersistentVolume
apiVersion: v1
metadata:
  name: maven
  labels:
    type: maven
    app: maven
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  glusterfs:
    endpoints: "glusterfs"
    path: data1
EOF

## create persistentVolumeClaim
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: maven-repo
  namespace: build
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 2Gi
  storageClassName:
  selector:
    matchLabels:
      type: "maven"
EOF

## when pvc is not binding to a released pv
kubectl patch pv maven -p '{"spec":{"claimRef": null}}'
