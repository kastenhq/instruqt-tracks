#!/bin/bash

# A VM image of 100GB was generated using the Ubuntu 20.04 LTS minimal
# release and the following commands. This needs to be run as root because
# instruqt launches terminals as root.

# Docs on image creation -
# https://cloud.google.com/compute/docs/images/create-delete-deprecate-private-images#console

# The image needs to be granted the role roles/compute.imageUser for the
# Instruqt service account (instruqt-track@instruqt-prod.iam.gserviceaccount.com)

apt update
apt -y install docker.io jq emacs vim bash-completion

KIND_VERSION="v0.11.1"
KUBECTL_VERSION="v1.20.1"
HELM_VERSION="v3.7.0"

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-$(uname)-amd64
chmod +x ./kind
mv ./kind /usr/local/bin

# Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
echo "alias k=kubectl" >> /root/.bashrc

# Install Helm 3
curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -zxvf - -C /usr/local/bin/ linux-amd64/helm --strip=1


# Download the base kind image
docker pull kindest/node:v1.21.1

cat > kind_config.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.21.1
  extraPortMappings:
  - containerPort: 32000
    hostPort: 32000
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32010
    hostPort: 32010
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32020
    hostPort: 32020
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32030
    hostPort: 32030
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32040
    hostPort: 32040
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32050
    hostPort: 32050
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32060
    hostPort: 32060
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32070
    hostPort: 32070
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32080
    hostPort: 32080
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 32090
    hostPort: 32090
    listenAddress: "0.0.0.0"
    protocol: TCP
EOF

kind create cluster --name k10-demo --config=./kind_config.yaml --wait 600s

# Change to the latest supported snapshotter version
SNAPSHOTTER_VERSION=v4.2.1

# Apply VolumeSnapshot CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Create snapshot controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml

git clone https://github.com/kubernetes-csi/csi-driver-host-path.git
cd csi-driver-host-path || exit
./deploy/kubernetes-1.21/deploy.sh
kubectl apply -f ./examples/csi-storageclass.yaml
kubectl patch storageclass standard \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass csi-hostpath-sc \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'




# https://github.com/NetApp/trident/issues/556
kubectl delete sc csi-hostpath-sc
cat <<EOF | kubectl create -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"  
  name: csi-hostpath-sc
allowVolumeExpansion: true
provisioner: hostpath.csi.k8s.io
parameters:
  fsType: ext4  
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF


# install kubectl completion and alias 
sudo apt-get install bash-completion

echo "alias k=kubectl" >> /root/.bashrc
echo "source /usr/share/bash-completion/bash_completion" >> /root/.bashrc
echo "source <(kubectl completion bash)" >> /root/.bashrc
echo "complete -F __start_kubectl k" >> /root/.bashrc
