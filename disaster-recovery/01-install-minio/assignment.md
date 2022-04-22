---
slug: install-minio
id: cysve1ohgi7d
type: challenge
title: Create an external object location on "datacenter east"
teaser: Understand why you need an external object storage location outside of your
  infrastructure to implement real disaster recovery.
notes:
- type: text
  contents: |-
    To understand the disaster recovery strategy that Kasten proposes let's first comeback on how Kasten protect
    your application.
- type: text
  contents: '![--](../assets/Diapositive13.jpeg)'
- type: text
  contents: |-
    Kasten snapshots a namespace which is made of PVCs and manisfests in an object that we call a restorepoint.
    ##
    Locally a restorepoint is stored in the kasten database, that we call the catalog. Note that we do not store the content of the snaphot in the catalog, we store the reference to the snapshot in the catalog.
    ##
    At this point  if you want to clone, or to restore to an anterior state you can. But what happens if you loose your snapshot because you deleted your namespace, because of a human error or a storage failure.
    ##
    you need to export your restore point to an alternate location.
- type: text
  contents: '![--](../assets/Diapositive14.jpeg)'
- type: text
  contents: |-
    You need to export your restorepoint with the content of your snapshots to an object storage in another location.
    Now if you loose the snapshots for whatever reason you can retreive the content from the object storage.
    ##
    For security reason all restore point are encrypted with key living in the catalog (data and spec included).
    ##
    But then what happen if you loose the catalog ? You also need to export the catalog and know its encryption key.
- type: text
  contents: '![--](../assets/Diapositive15.jpeg)'
- type: text
  contents: |-
    It’s why we also export the catalog but with a provided user key to let the user restore the catalog. That enable him to retreive the keys and afterward his namespaces.

    At this point we consider that we have enabled disaster recovery. We have reach a point were we can completly recover from a disaster.

    However doing that just once is not sufficient, we need to do that regulary. In other words as a policy.
- type: text
  contents: '![--](../assets/Diapositive16.jpeg)'
- type: text
  contents: |-
    With the help of policy frequency we automate the repetion of this processus in a @hourly, @daily, @weekly, @monthly or @yearly manner.
    To get a better coverage we can use automatic discovery of application with the help of labels.
- type: text
  contents: '![--](../assets/Diapositive17.jpeg)'
- type: text
  contents: |-
    With the help of policy label selector we can capture automatically new namespace for disaster protection.
    Let's imagine now a disaster that completly remove your application with no chance to recover your storage or applications.
- type: text
  contents: '![--](../assets/Diapositive18.jpeg)'
- type: text
  contents: |-
    A Disaster happened … How do we rebuild ?
    Once you infrastructure is back up and running you need to reinstal a blank Kubernetes cluster.
- type: text
  contents: '![--](../assets/Diapositive19.jpeg)'
- type: text
  contents: First we reinstall kubernetes in the datacenter or in another datacenter.
- type: text
  contents: '![--](../assets/Diapositive20.jpeg)'
- type: text
  contents: Then we reinstall kasten and you'll execute the disaster recovery procedure
- type: text
  contents: '![--](../assets/Diapositive21.jpeg)'
- type: text
  contents: |-
    You restore the catalog by providing the user key that you choose for disaster recovery enablement.
    You'll be able now to use information on the restorepoint.
- type: text
  contents: '![--](../assets/Diapositive22.jpeg)'
- type: text
  contents: |-
    Restore points that are in the catalog have reference from the object storage.
    It's all Kasten need to restore your applications.
- type: text
  contents: '![--](../assets/Diapositive23.jpeg)'
- type: text
  contents: |-
    With the restore point back you are able to restore the application namespace.
    ##
    Kasten let you do that very easily it’s why it’s easy to do that in a completly automated way if needed.
- type: text
  contents: |-
    For the need of this track we emulate the datacenter east by installing minio on a different machine from the cluster.
    ##
    This is of course not the reality because we have the limitation of a lab that make us work in the same datacenter, but
    the process is the same.
tabs:
- title: Terminal minio
  type: terminal
  hostname: minio
- title: Terminal k8s
  type: terminal
  hostname: k8svm
- title: Minio console
  type: website
  url: http://minio.${_SANDBOX_ID}.instruqt.io:9001
  new_window: true
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
difficulty: basic
timelimit: 1800
---

# Launch minio on the minio terminal.

```
mkdir /data
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  minio/minio server /data --console-address ":9001"
```

Open the minio console tab and use minioadmin/minioadmin credentials to connect to the console.



