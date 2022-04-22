---
slug: deeep-dive-k10-csi-backup
id: kzysck2pk31u
type: challenge
title: CSI backup
teaser: 'Let''s focus on the most standard and simple backup: the CSI backup.'
notes:
- type: text
  contents: |-
    We're going on this session to explore CSI backup.
    But first let's see the different kind of Backup that Kasten support.
- type: text
  contents: |-
    The different form of backup are
    - Direct integration, Kasten create native snapshot by directly speaking to the api of the storage provider
    - CSI, Kasten use CSI snapshot API if supported by the storage provider
    - Logical Backup, Kasten hand off the responsability of the backup to Kanister
    - Generic Backup, it's a special form of Logical Backup using a datamover sidecar in the stateful workload
    - Consistent backup, Kasten do the backup (DI, CSI) but hand off the responsability of preparing the data to Kanister
- type: text
  contents: |-
    ### CSI vs Generic vs Logical
    ![Direct integration/CSI vs Generic Backup](../assets/sidecar-vs-snapshot.png)
- type: text
  contents: |-
    In CSI/Direct Integration once the snapshots of the PVC are taken a temporary PVC clone is created in the kasten-io namespace.
    This clone PVC is used by the datamover (Kopia) to export the data to the object location target (S3, NFS ...).
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
We have already set up the CSI intergration in this lab thanks to the annotation we put on the snapshotclass during
the installation of Kasten.

That's all it take for Kasten to work with csi : annotate the snapshotclass

```
kubectl annotate volumesnapshotclass csi-hostpath-snapclass k10.kasten.io/is-snapshot-class=true
```

You already did this operation at the beginning of the lab and don't need to do it again.

#  Volumesnapshot and clone

We alaready set up a policy on mongodb with an export location, let's observe the objects that are created when launching a backup.

There is 3 tabs terminal
- Terminal Snapshot
- Terminal PVC
- Terminal Pods

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

# Observe the object lifecycle

Nom launch manually the mongodb-backup policy and observe the creation and deletion of objects.

- First new snapshot in the mondodb namespace appears.
- Second clone pvc are created in the kasten-io namespace.
- Third copy-vol-data pods should spin up and terminate when export finish, clone are also removed.

WARNING: sometimes snapshots on mongodb namespace never get ready to use.
We're still investigating on this issue.

If this happen. Stop the track and restart by skipping directly to the CSI backup-challenge.
Preparation of the machine and re-execution of the previous steps will take around 10 minutes.

## Chalenge CSI backup

Open csi-backup-challenge.txt and remove the Inaccurate sentences, there is a read-only copy that you can use.






