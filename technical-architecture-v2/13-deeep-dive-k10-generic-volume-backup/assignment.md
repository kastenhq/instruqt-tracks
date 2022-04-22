---
slug: deeep-dive-k10-generic-volume-backup
id: iuztnbiyulfd
type: challenge
title: Generic backup
teaser: |-
  You're storage does not have any snapshot capacity (NFS, Azure File ...) and
  you don't want or can't use logical backup : use the generic backup.
notes:
- type: text
  contents: We're going on this session to explore generic backup.
- type: text
  contents: |-
    Generic backup is useful when you have no snapshot that you can use with your storage solution, for instance:
    - NFS
    - Azurefile
    - In tree vmware volume
    - Glusterfs
    - ...
    And you can't use logical backup.
- type: text
  contents: |-
    Generic backup is the lower half of the picture.
    ![Direct integration/CSI vs Generic Backup](../assets/sidecar-vs-snapshot.png)
- type: text
  contents: It works by introducing a kanister sidecar in the existing pod that are
    working with the PVC. This way the kanister-sidecar can access the volumes and
    do a kopia snapshot.
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
- title: Terminal mongodb Snapshots
  type: terminal
  hostname: k8svm
- title: Terminal mongodb Pods
  type: terminal
  hostname: k8svm
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
difficulty: basic
timelimit: 1000
---

## Generic backup and consistent backup are not compatible

Generic backup and consistent backup are not compatible, we need to remove the previous kasten annotation
on the mongo statefulset

```
kubectl annotate statefulset mongo-mongodb kanister.kasten.io/blueprint- \
      --namespace=mongodb
```

# Enable generic backup

To enable generic backup we need to change the kasten installation

```
helm upgrade k10 kasten/k10 -n kasten-io \
  --set injectKanisterSidecar.enabled=true \
  --set-string injectKanisterSidecar.objectSelector.matchLabels.component=db \
  --set-string injectKanisterSidecar.namespaceSelector.matchLabels.k10/injectKanisterSidecar=true --wait
```

`objectSelector`is to point the object on which we should apply kanister injection.

`namespaceSelector` is for the namespace where we should apply kanister injection.

Hence in this case we apply kanister injection if the workload has the label `component=db`
if it belongs to a namespace that has the label `k10/injectKanisterSidecar=true`.

Behind the hood it create a MutatingWebHook

```
kubectl get mutatingwebhookconfigurations.admissionregistration.k8s.io k10-sidecar-injector -o yaml
```
# Apply the change on mongodb

First Generic backup and consistent

On mongodb only the statefulset mongo-mongodb is involved.

```
kubectl label ns mongodb k10/injectKanisterSidecar=true
kubectl label -n mongodb statefulset mongo-mongodb component=db
```

Now check the number of container inside the pods
```
kubectl get po -n mongodb
```

You should obtain something like this after all the pods mongo-mongodb-x has restarted.
```
NAME                      READY   STATUS    RESTARTS   AGE
mongo-mongodb-0           2/2     Running   0          104s
mongo-mongodb-1           2/2     Running   0          2m14s
mongo-mongodb-arbiter-0   1/1     Running   0          6m39s
```

The mongo-mongodb staefulset has now 2 containers.

```
kubectl -n mongodb get sts mongo-mongodb -o jsonpath='{.spec.template.spec.containers[*].name}'
```

You should obtain something like this

```
mongodb kanister-sidecar
```

# Run once a backup

In the mongodb snapshot terminal
```
kubectl get volumesnapshot -n mongodb -w
```

In the mongodb pod terminal
```
kubectl get po -n mongodb -w
```

And run once again the mongodb policy.

Then you should see no change in the number of snapshot and no extra pods created has well because container
are already in the stateful workload

# Warning

Generic volume snapshot is actually not a snapshot because it operate on the filesystem. Your backup won't be
**crash consistent**. Hence use it knowing that if intense activity are running on the pvc you may face
dirty read.