---
slug: install-mongodb
id: t7pdj02kkyz7
type: challenge
title: Install MongoDB
teaser: Install MogoDB
notes:
- type: text
  contents: As an intermediate step, we will create a mongodb namespace where we can
    exercice both consistent and logical backup
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
- title: Minio Dashboard
  type: service
  hostname: k8svm
  path: /
  port: 32010
difficulty: basic
timelimit: 400
---
To experiment with backup and recovery of a cloud-native application, we will install MongoDB and create a database in this step.

First, install Mongodb using the following commands:

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
kubectl create namespace mongodb
helm install mongo bitnami/mongodb --namespace mongodb \
    --set architecture="replicaset"
```

To ensure that mongodb is running, check the pod status to make sure they are all in the `Running` state:

```console
watch -n 2 "kubectl -n mongodb get pods"
```

Once all pods have a `Running` status, hit `CTRL + C` to exit watch and then run the following commands to create a collection with some data.


Run a mongo client
```console
export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace mongodb mongo-mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 --decode)
kubectl run --namespace mongodb mongo-mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image docker.io/bitnami/mongodb:4.4.11-debian-10-r12 --command -- mongo admin --host "mongo-mongodb-0.mongo-mongodb-headless:27017,mongo-mongodb-1.mongo-mongodb-headless:27017" --authenticationDatabase admin -u root -p $MONGODB_ROOT_PASSWORD
```

Now create data
```
db.createCollection("log", { capped : true, size : 5242880, max : 5000 } )
db.log.insert({ item: "card", qty: 15 })
db.log.insert({ item: "dice", qty: 3 })
db.log.find()
```

When all seems good you can exit
```
exit
```

# Create a policy with the export location profile minio.

Create an hourly policy on the mongodb namespace with export to kasten-bucket location profile.

Execute it once and validate that all went fine. If successfull run it a second time and follow the creation
of object :

- To follow up the creation of snapshot in mongodb namespace
```
kubectl get volumesnapshot -n mongodb -w
```

- To follow up the creation of clone snapshot and pvc during export in kasten-io namespace
```
watch kubectl get volumesnapshot,pvc -n kasten-io
```

- To follow up the snap process
```
kubectl logs -c csi-snapshotter csi-hostpathplugin-0
```

# Deletion and restoration of the workloads

Exercice a restoration by deleting first all the content of the namespace

```
helm uninstall -n mongodb mongo
kubectl delete pvc -n mongodb --all
```

Use Kasten to restore and check all data in the log collection is here.