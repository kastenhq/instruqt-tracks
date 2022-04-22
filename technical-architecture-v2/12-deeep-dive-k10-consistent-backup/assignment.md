---
slug: deeep-dive-k10-consistent-backup
id: kjofjmlqrihw
type: challenge
title: Consistent backup
teaser: |-
  You want to snapshot your volumes for taking a backup but need to prepare
  the data: use the consistent backup.
notes:
- type: text
  contents: We're going on this session to explore consistent backup.
- type: text
  contents: |-
    Consistent backup is useful when you have snapshot that you can use with your storage solution, but you need to prepare your data
    before taking the snapshot to make sure they are consistent, and your workload will be able to restart without any issues.
- type: text
  contents: |-
    ### Without blueprint
    ![Without blueprint](../assets/blueprint-logical-without-blueprint.drawio.png)
- type: text
  contents: |-
    ### With consistent blueprint
    ![With consistet blueprint](../assets/blueprint-app-consistent-app-consistent.drawio.png)
tabs:
- title: Terminal mongodb snapshot
  type: terminal
  hostname: k8svm
- title: Terminal kasten-io PVC
  type: terminal
  hostname: k8svm
- title: Terminal kasten-io pods
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

Let's use an existing consistent blueprint for mongodb.

```
kubectl apply -f /root/mongodb-hooks.yaml --namespace kasten-io
```

Check the blueprint and the 2 operations : backupPrehook and backupPosthook.

## BackupPrehook

```
cat /root/mongodb-hooks.yaml|grep -A22 backupPrehook:
```
This hook is called before kasten take the backup of the pvc attached to the workload.

We execute a KubeExec, which means that we don't create a new pod but execute on the existing pod.

we call the internal fuction of mongodb `db.fsyncLock()`

It forces the mongod to flush all pending write operations to disk and locks the entire mongod instance to prevent additional writes until the user releases the lock with a corresponding db.fsyncUnlock() command.


## BackupPosthook
```
cat mongodb-hooks.yaml | grep -A22 backupPosthook:
```
This hook is called before kasten took the backup of the pvc attached to the workload.

Again we use KubeExec but this time we call `db.fsyncUnlock()`

# On all the pods

Notice also this particular pod selector.

```
pods: "{{ range .StatefulSet.Pods }} {{.}}{{end}}"
```

It's using go-template construct to apply the KubeExec action on each pods of the statefulset.

## apply the blueprint on the stateful set

```
kubectl annotate statefulset --overwrite mongo-mongodb kanister.kasten.io/blueprint='mongo-hooks' \
      --namespace=mongodb
```

# Observe the backup

You'll have issue to observe anything because all happen in KubeExec.

However the backup process is the same than csi backup. We just add behaviour before and after the snapshot.

In Terminal snapshot run :
```
kubectl get volumesnapshot -n mongodb -w
```

In Terminal PVC :
```
kubectl get pvc -n kasten-io -w
```

In Terminal pods :
```
kubectl get pods -n kasten-io -w
```

And run again the backup policy on mongodb.

# Consistent vs Logical

With consistent backup you have the best of the two words
- Consistent backup
- Use of our datamover kopia that only capture the change
- No delete action to implement it's  managed by Kasten

But this is not possible for any databases, for instance elasticsearch database does not support consistent filesystem backup.

# Challenge consistent backup

Open the file /root/consistent-backup-challenge.txt and remove the inaccurate sentence.