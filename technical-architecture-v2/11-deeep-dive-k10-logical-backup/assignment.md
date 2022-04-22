---
slug: deeep-dive-k10-logical-backup
id: nwvejp1j1vnk
type: challenge
title: Logical backup
teaser: 'Want to implement your own backup path for a specific service : use logical
  backup.'
notes:
- type: text
  contents: |-
    We're going on this session to explore Logical backup.
    When doing logical backup, Kasten handoff the backup to Kanister.
    ### But what is Kanister ?
- type: text
  contents: |-
    Kanister is a framework to capture application specific data management tasks in blueprints which
    can be easily shared and extended.
- type: text
  contents: |-
    Kanister will be covered in a lab extensively but for the moment let's stick to this simple but accurate ideas :
    - Kanister execute `actions` defined in a `blueprint`
    - Kasten will ask Kanister to execute the `blueprint` if a stateful workload is annotated with `kanister.kasten.io/blueprint='<blueprint-name>'`
      when a backupAction, a restoreActin or a retireAction is created.
    - Then the workload becomes the context of the blueprint
- type: text
  contents: |-
    Blueprint output information in the restorepoint
    - The blueprint can define which ouput of this actions will be stored in the `restorepoint`.
    - Kasten will update the restore point to add this output in the restore point in the form of key/value
    - For logical backup only `backup`, `restore` and `delete` actions can be defined in the blueprint
    - `backup` is called when a backupAction is created, output are written
    - `restore` is called when a restoreAction is created, output are read, `restore` use the output of `backup`
    - `delete`is call when a retireAction is created, output are read also, `delete` use the output of `backup`
- type: text
  contents: |-
    ### Without blueprint
    ![Without blueprint](../assets/blueprint-logical-without-blueprint.drawio.png)
- type: text
  contents: |-
    ### With logical blueprint
    ![With logical blueprint](../assets/blueprint-logical-logical.drawio.png)
tabs:
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
Let's use an existing logical blueprint for mongodb.

```
curl https://raw.githubusercontent.com/kanisterio/kanister/0.72.0/examples/stable/mongodb/blueprint-v2/mongo-blueprint.yaml > mongo-blueprint.yaml
kubectl apply -f mongo-blueprint.yaml --namespace kasten-io
```

Check the blueprint and the 3 operations : backup, restore and delete.

## Backup
```
cat mongo-blueprint.yaml | grep -A30 backup:
```
The blueprint do a `mongodump` using the secret and pass the file to kopia.
The kopiasnapshot reference is passed to the restore point by adding it to the outPutArtifacts.

## Restore
```
cat mongo-blueprint.yaml | grep -A29 restore:
```
The blueprint do a `mongorestore` using the inputArtifact which is fed by the previous output artifact

## Delete
```
cat mongo-blueprint.yaml | grep -A25 delete:
```

The blueprint delete the kopia snapshot.

## Kubetask

Means we execute each actions in a separate new pods. Another approach is to use kubexec where you execute the action in an
existing pods.

## Kando

Kando is an internal tool, installed in the Kanister image. It is provided by Kanister that let you do kopia operation and output values.

# Apply the blueprint

```
kubectl annotate statefulset mongo-mongodb kanister.kasten.io/blueprint='mongodb-blueprint' \
      --namespace=mongodb
````

In the mongodb snapshot terminal
```
kubectl get volumesnapshot -n mongodb -w
```

In the mongodb pod terminal
```
kubectl get po -n mongodb -w
```

Now run again the policy and observe the two terminals.

## Chalenge Logical backup

Open the file /root/logical-backup-challenge.txt and remove the inaccurate sentence.

