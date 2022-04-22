---
slug: install-minio
id: vjqz3ukonywk
type: challenge
title: Create an external object location to  run the migration.
teaser: Understand why you need an external object storage location to run migration.
notes:
- type: text
  contents: |-
    To understand how you can use Kasten to migrate an application let's first comeback on how Kasten protect
    your application and export it.
- type: text
  contents: |-
    Kasten snapshots namespaces which are made of PVCs and manisfests in an object that we call a restorepoint.
    ##
    Locally a restorepoint is stored in the kasten database, that we call the catalog. Note that we do not store the content of the PVC snaphots in the catalog, we store the reference to the snapshot in the catalog.

    ![--](../assets/Diapositive26.jpeg)
- type: text
  contents: |-
    This restore point is exported in a portable manner.
    ##
    We create a temporary clone of the PVC from the snapshot and use our datamover Kopia to export the data to the
    object location profile.
    ![--](../assets/snaphot-export.png)
- type: text
  contents: |-
    We can also send only the reference to the snapshot and not doing portable migration. This approach
    could be very interesting if you're exporting on the same platform, for instance AWS to AWS or
    Nutanix to Nutanix.

    ![--](../assets/export-reference-focus.png)
- type: text
  contents: |-
    If no snapshot is possible we can use Generic backup.
    ##
    Generic backup by nature is an export, it introduces a Kopia sidecar in the workload that do the data moving.

    ![--](../assets/generic-export.png)
- type: text
  contents: |-
    There is also logical backup where we leverage a backup tool from the dataservice.
    ##
    Logical backup by nature is also an export, it's often a temporary pod that embed Kopia tools and backup tools to execute the backup and the data moving.

    ![--](../assets/logical-export.png)
- type: text
  contents: |-
    On the destination cluster, Kasten is also installed and you create an import policy that will regulary
    import the last restore points.

    ![--](../assets/Diapositive27.jpeg)
- type: text
  contents: |-
    With the restorepoints you can now launch restoreaction in the destination
    cluster.

    ![--](../assets/Diapositive28.jpeg)'
- type: text
  contents: |-
    And apply transformations, for instance do not restart the workload by
    setting replicas at zero.

    ![--](../assets/Diapositive29.jpeg)
- type: text
  contents: |-
    In this track we'll install :
    - the object location (minio) on the minio machine
    - Kasten on the source cluster on the k8s machine
    - Kasten on the destination cluster on the k8sdr machine

    For the moment let's install minio.
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
timelimit: 1200
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



