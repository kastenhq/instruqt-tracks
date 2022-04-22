---
slug: install-k10
id: s5ruihrfqpkk
type: challenge
title: Install K10
teaser: Install K10 and Configure Storage
notes:
- type: text
  contents: |-
    Kasten by default take the **snapshot** path to backup your stateful workload. It's the simplest and more
    straigth forward approach to protect your data because your backup are **crash consistent** and at least you
    export a copy of your data in an external storage.
    ##
    However being **crash consistent** does not mean being **application consistent**. For performance
    reason databases keep in memory many datas and flush them to the disk at specific intervals. Hence
    the state of the disks is not necessary the state of the database. Hopefully **Kasten** integrate with the
    **Kanister** project to help you build consistent backup.
- type: text
  contents: |-
    # 2 approaches to be application consistent
    There is 2 approaches to be application consistent:
    1. **Logical backup** : Take a logical dump of your database (mysqldump, pgdump, mondodump ...) and export it to your external storage. In this case you don't want to take a snapshot of the disk anymore, but you need to implement also a custom restore path
    2. **App consistent backup** : Call a database primitive to flush the data on the disk and lock the database. Often this approach involve two primitive call, one before the volume snapshot and one after the volume snapshot. We'll see that this approach is the more efficient in a storage standpoint but also the more delicate because your database is locked between the two calls.
- type: text
  contents: |-
    ### Without application consistency
    ![Without blueprint](../assets/blueprint-logical-without-blueprint.drawio.png)
- type: text
  contents: |-
    ### Logical backup
    ![With logical blueprint](../assets/blueprint-logical-logical.drawio.png)
- type: text
  contents: |-
    ### App consistent backup
    ![With consistet blueprint](../assets/blueprint-app-consistent-app-consistent.drawio.png)
- type: text
  contents: |-
    # How that works ?
    To make that possible Kasten integrate a data management tool for kubernetes : [Kanister](https://kanister.io)
    ###
    Kanister allows domain experts to capture application specific data management tasks in blueprints which can be easily shared and extended. The framework takes care of the tedious details around execution on Kubernetes and presents a homogeneous operational experience across applications at scale.
- type: text
  contents: |-
    # what we'll study
    - We'll study what is Kanister without using the Kasten integration. This step will allow us to understand the Kanister component and functionning
    - Then we'll study Kanister integrated with Kasten
    ###
    But for now let's setup our lab by installing Kasten ! This install will also install Kanister.
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
difficulty: basic
timelimit: 1200
---
# Install Kasten K10

```console
helm repo add kasten https://charts.kasten.io/
helm repo update

kubectl create ns kasten-io

# install a lab licence
kubectl create -f license-secret.yaml

helm install k10 kasten/k10 --namespace=kasten-io
```

To ensure that Kasten K10 is running, check the pod status to make sure they are all in the `Running` state:

```console
watch -n 2 "kubectl -n kasten-io get pods"
```

Once all pods have a Running status, hit `CTRL + C` to exit `watch`.

# Configure the Local Storage System

Once K10 is running, use the following commands to configure the local storage system.

```console
kubectl annotate volumesnapshotclass csi-hostpath-snapclass k10.kasten.io/is-snapshot-class=true
```