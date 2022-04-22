---
slug: install-nfs
id: f3l7e6gi5e43
type: challenge
title: Install NFS
teaser: Create an NFS server
notes:
- type: text
  contents: |-
    A typical airgapped (disconnected) install involve solving the challenge of downloading Kasten images from a private registry.

    Also the storage location can't be a public S3 endpoint, even if that's possible to deploy private S3 endpoint most of the
    time NFS is already there since a long time and teams prefer to leverage this tool that they know very well.
- type: text
  contents: Hence this lab will involve installing NFS and a private registry. On
    this challenge we'll concentrate on NFS.
tabs:
- title: Terminal nfs
  type: terminal
  hostname: nfs
- title: Terminal k8s
  type: terminal
  hostname: k8svm
difficulty: basic
timelimit: 2000
---

# Let's create a NFS service in the NFS machine

Use the nfs terminal to install the nfs-kernel-server
```
sudo apt-get update
sudo apt install -y nfs-kernel-server
```

Create and expose the /nfs directory
```
sudo mkdir /nfs
sudo chown nobody:nogroup /nfs
echo "/nfs p-${INSTRUQT_PARTICIPANT_ID}-k8svm.c.instruqt-prod.internal(rw,sync,no_subtree_check)" >> /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```

# Use the k8s terminal now

Test the NFS client

Install the nfs client.
```
sudo apt-get update
sudo apt-get install -y nfs-common
```

Mount the share
```
mkdir /mnt/nfs
mount p-${INSTRUQT_PARTICIPANT_ID}-nfs.c.instruqt-prod.internal:/nfs /mnt/nfs
```

# Check nfs work properly

on k8svm
Check nfs work properly
```
touch /mnt/nfs/test
```

On nfs
```
ls /nfs
```

You should see
```
test
```