#!/bin/bash

# A VM image of 100GB was generated using the Ubuntu 20.04 LTS minimal
# release and the following commands. This needs to be run as root because
# instruqt launches terminals as root.

# Docs on image creation -
# https://cloud.google.com/compute/docs/images/create-delete-deprecate-private-images#console

# The image needs to be granted the role roles/compute.imageUser for the
# Instruqt service account (instruqt-track@instruqt-prod.iam.gserviceaccount.com)

apt update
apt -y install docker.io jq emacs vim

KIND_VERSION="v0.11.1"
KIND_NODE_TAG="v1.20.7"
KUBECTL_VERSION="v1.20.7"
HELM_VERSION="v3.6.3"
SNAPSHOTTER_VERSION="v4.2.0"
CSI_DEPLOY_VERSION="1.20"

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-$(uname)-amd64
chmod +x ./kind
mv ./kind /usr/local/bin

# Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# Install Helm 3
curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -zxvf - -C /usr/local/bin/ linux-amd64/helm --strip=1

# Download the base kind image
docker pull kindest/node:${KIND_NODE_TAG}

cat > kind_config.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:${KIND_NODE_TAG}
  extraPortMappings:
  - containerPort: 32000
    hostPort: 32000
    listenAddress: "0.0.0.0"
    protocol: TCP
EOF

kind create cluster --name k10-demo --config=./kind_config.yaml --wait 600s

# Change to the latest supported snapshotter version
# Apply VolumeSnapshot CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Create snapshot controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml

# install hostpath csi
git clone https://github.com/kubernetes-csi/csi-driver-host-path.git
cd csi-driver-host-path || exit
./deploy/kubernetes-${CSI_DEPLOY_VERSION}/deploy.sh
kubectl apply -f ./examples/csi-storageclass.yaml

# change default sc
kubectl patch storageclass standard \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass csi-hostpath-sc \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
