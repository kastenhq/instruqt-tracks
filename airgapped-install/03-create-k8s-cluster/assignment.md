---
slug: create-k8s-cluster
id: 4itugni4yivv
type: challenge
title: Create the k8s cluster
teaser: |-
  Because of our internal registry is not a secured one, we need to create the k8s cluster with
  specific configuration.
tabs:
- title: Terminal k8s
  type: terminal
  hostname: k8svm
- title: Terminal nfs
  type: terminal
  hostname: nfs
difficulty: basic
timelimit: 1200
---

# Recreate the k8s cluster with the registry

For the lab we create Kind cluster, and special configuration is required
to have kind cluster accept an insecure registry. It's why we ask you here
to recreate it, but on a normal deployment the kubernetes cluster and the
registry would be already configured.

On the k8s machine

```
cat <<EOF | kind create cluster --name k10-demo --config=-
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
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000"]
    endpoint = ["http://nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000"]
EOF
```

# Test NFS and external registry all together

Let's create a pod that use a NFS PVC and an image that come from the internal registry

```
kubectl create ns kasten-io
```

Create the nfs PV and the corresponding PVC.
```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs-kasten
spec:
  claimRef:
    name: pvc-nfs-kasten
    namespace: kasten-io
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    path: /nfs
    server: p-${INSTRUQT_PARTICIPANT_ID}-nfs.c.instruqt-prod.internal
    readOnly: false
  mountOptions:
      - hard
      - nfsvers=4.1
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs-kasten
  namespace: kasten-io
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
EOF
```


Create a pull secret
```
kubectl create -n kasten-io secret docker-registry nfs-${INSTRUQT_PARTICIPANT_ID}-registry-secret \
   --docker-username=testuser \
   --docker-password=testpassword \
   --docker-email=unused \
   --docker-server=http://nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000/v2/
```

Now deploy a pod based on an internal registry and mounting this nfs PVC
```
cat <<EOF | kubectl create -n kasten-io -f -
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: airgapped-alpine
  name: airgapped-alpine
spec:
  imagePullSecrets:
  - name: nfs-${INSTRUQT_PARTICIPANT_ID}-registry-secret
  containers:
  - args:
    - tail
    - -f
    - /dev/null
    volumeMounts:
    - name: data
      mountPath: /data
    image: nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000/alpine
    name: airgapped-alpine
    resources: {}
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-nfs-kasten
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
EOF
```

Test the creation of a file from a pod
```
kubectl exec  airgapped-alpine -n kasten-io -- touch /data/test-from-a-pod
```

On nfs machine check the file has been created

```
ls /nfs
```

we don't need anymore this pod but want to keep the nfs PVC storage so let's delete it.

On k8s machine
```
kubectl delete po -n kasten-io airgapped-alpine
```

