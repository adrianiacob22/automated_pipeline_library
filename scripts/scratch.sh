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

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: jenkins-admin
    namespace: kube-system
EOF
SA_NAME='jenkins-admin'
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep ${SA_NAME} | awk '{print $1}')
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

# cat <<EOF | kubectl apply -f -
# kind: Service
# apiVersion: v1
# metadata:
#  name: jenkins
#  namespace: build
# spec:
#  type: ExternalName
#  externalName: jenkins.local.net
# EOF
#
# cat <<EOF | kubectl apply -f -
# kind: Service
# apiVersion: v1
# metadata:
#  name: jenkins
#  namespace: build
#  labels:
#    ep: jenkins
# spec:
#  ports:
#  - port: 27443
#    targetPort: 443
# ---
# kind: Endpoints
# apiVersion: v1
# metadata:
#  name: jenkins
#  namespace: build
#  labels:
#    ep: jenkins
# subsets:
#  - addresses:
#      - ip: 192.168.100.3
#    ports:
#      - port: 443
# EOF






cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
spec:
  containers:
  - name: dnsutils
    image: gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
EOF
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: openssl
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: frapsoft/openssl
    imagePullPolicy: IfNotPresent
    name: openssl
  restartPolicy: Always
EOF

## when pvc is not binding to a released pv
kubectl patch pv maven -p '{"spec":{"claimRef": null}}'

##
echo "-----BEGIN CERTIFICATE-----
MIIDYjCCAkqgAwIBAgIIF+Dqjah0m08wDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
AxMKa3ViZXJuZXRlczAeFw0yMDA0MTcwOTI4MDhaFw0yMTA0MTcwOTI4MDhaMBkx
FzAVBgNVBAMTDmt1YmUtYXBpc2VydmVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEAyaUHbLqMTsq4Ijhf6LSyei68DTF9qyqERjy4S924SG79oD4ee9E3
l3AwvaWJryv0ktieED3fvl5nRf5/C19/BQSaYPHHNmLCWBc8n1ZVI8VdvZBsvYHQ
bBC2KZeuCnMwHKWHMOpZ9gohirVirJEeF/WCfqUi/R0X0KokkTRxr2heymaCT8tH
TvPTqE/PUqvGfsXMBQoRhaARoDxJOVVf729nMHik1Drb8wt6BbWzMj45gRBvfyLx
c+VZHuWwKP83tz2dByOeD1jWrD6nAl3EY8IRWwAu2lAvrGCumkCDSS8cEmgsPhwq
Pqsq6jQWpMzrlc3Vzxm2kAukfLF/yK7L2wIDAQABo4GxMIGuMA4GA1UdDwEB/wQE
AwIFoDATBgNVHSUEDDAKBggrBgEFBQcDATCBhgYDVR0RBH8wfYIRa21hc3Rlci5s
b2NhbC5uZXSCCmt1YmVybmV0ZXOCEmt1YmVybmV0ZXMuZGVmYXVsdIIWa3ViZXJu
ZXRlcy5kZWZhdWx0LnN2Y4Ika3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVy
LmxvY2FshwQKYAABhwSsKipkMA0GCSqGSIb3DQEBCwUAA4IBAQCMDkq6nIqqK/Pr
IEocup/veFMwT8ywmr9RlDOFbW1oNtdr31x8XuSkBNsG0nHk4QLSfXrVh2fhbKR9
SMJPPjHfgrdJXeoTOG5AV74vuPwK0HMJHCvzUxjlem3ZRJa59NfsQdhZ8nVzohd5
Luszi7SAn1TX5mDWYegluHeH28/4BkZPo4685w1/hdjWwRcgZ1YMCvmuVsqIKjeQ
b505wDwmfE/f7QjS50Irgwbi4Y74Q41DNCShtRwRwLdvWM5hJdWEAqMxNLCUxXlo
3faPXNMRtztAaW2U4raSUmozUoyr/36/+OFaxl89KGcJfxXo5pcqmGtzWdpoKZv1
UFQL797q
-----END CERTIFICATE-----" > /tmp/kube.der

keytool -importcert -alias jenkins-CA -keystore /usr/local/openjdk-11/lib/security/cacerts -file /tmp/kube.der -storepass changeit -noprompt

# tag and push docker images to nexus
docker build -t jenkins-jnlp-slave .
docker tag jenkins-jnlp-slave:latest nexus.local.net:8123/jenkins-jnlp-slave:20200420
docker tag nexus.local.net:8123/jenkins-jnlp-slave:20200420 nexus.local.net:8123/jenkins-jnlp-slave:latest
docker push nexus.local.net:8123/jenkins-jnlp-slave:20200420
docker push nexus.local.net:8123/jenkins-jnlp-slave:latest

# Create docker registry secret in Kubernetes
 kubectl create secret generic docker-repo --from-file=.dockerconfigjson=/home/adrian/.docker/config.json --type=kubernetes.io/dockerconfigjson
