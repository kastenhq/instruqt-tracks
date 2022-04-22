---
slug: deeep-dive-k10-service-api
id: awjpk9szwnhk
type: challenge
title: The catalog and the aggregated API
teaser: |-
  Where are stored the backupaction, the restoreaction and all the kasten...action ? You'll find out
  in this challenge an in depth view on the catalog and the Kasten aggregated API.
notes:
- type: text
  contents: k10 follow cloud native best practices and feature a micro-service architecture.
    To have a better understanding of what is micro-services we strongly recommend
    this [Comprehensive guide](https://www.ibm.com/cz-en/cloud/learn/microservices).
- type: text
  contents: |-
    # Composition of the architecture
    we identify 4 big components made themselves of microservices
    - **API : catalog, aggregatedapi, crypto**
    - GUI : gateway, auth, frontend, dashboardbff, state
    - Execution : config, jobs, executor, kanister
    - Monitoring : logging, prometheus, grafana, metering
- type: text
  contents: |-
    This session details the API part of the architecture:
    - catalog
    - aggregated API
    - crypto service
    These microservices are responsible for peristence
    of the restorepoint and the encryption keys, they also store and serve all the kasten actions api.
- type: text
  contents: '![architecture components](../assets/architecture-components-api.png)'
- type: text
  contents: |-
    Other elements like Profile or Policies CRD are created and validated by the config service.
    They are also part of the Kasten API but this is not our main preocupation and they are already covered in the API lab.
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
- title: Boltdbweb
  type: service
  hostname: k8svm
  path: /
  port: 32020
difficulty: basic
timelimit: 300
---

# Understand the catalog

The catalog is where we persist the restorepoint and encryption key.

Catalog is where the critical information for restoring your application is leaving.

It's using the key value database [boltdb database](https://github.com/boltdb/bolt) a pure
go key-value database.



# Visualize the catalog

Let's use boltdbweb to visit it.

Because only one process can acquire the boltdb file we need to scale down the catalog-svc deployment first.

```
kubectl -n kasten-io scale deploy catalog-svc --replicas 0
```

Now create the boltdbweb deployment
```
cat <<EOF |kubectl -n kasten-io create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: boltdbweb
  labels:
    app: boltdbweb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: boltdbweb
  template:
    metadata:
      labels:
        app: boltdbweb
    spec:
      containers:
      - name: boltdbweb
        image: michaelcourcy/boldbweb
        resources:
            requests:
              memory: 256Mi
              cpu: 200m
        args:
        - --db-name=/mnt/kasten-io/catalog/model-store.db
        - --port=8080
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: data
          mountPath: /mnt
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: catalog-pv-claim
EOF

```

Now create the node-port service to expose boltwebdb.
```
cat <<EOF |kubectl -n kasten-io create -f -
apiVersion: v1
kind: Service
metadata:
  name: boltdbweb-nodeport
spec:
  selector:
    app: boltdbweb
  ports:
  - name: http
    port: 8080
    nodePort: 32020
  type: NodePort
EOF

```

Open now the boltdbweb tab.

Use the buckets menu items to identify the different collections used by kasten to maintain its state.

## Catalog challenge 1

Open the file /root/catalog-challenge.txt write
- on the first line the name of the bucket that hold the value of SCHEMAVERSION
- on the second line the name of the bucket that hold the values of the spec you backup in a namespace

## Kasten upgrade

SCHEMAVERSION is used when you upgrade kasten, it help kasten to build the appropriate migration of the boltdb database.

When upgrade occur, kasten service are stopped and another file is copied from `model-store.db`.

Upon succesful upgrade the new file replace the old one, and kasten restart as normal.

Otherwise kasten rollback to the old and helm rollback bring everything back in the previous version. Upgrade failed
but you can still work with the previous version of Kasten.


# If catalog cease to work

For the moment catalog doesn't work because we scaled it down, go to the interface and check that Dashboard :

- Can't show anymore any actions (backupaction, restoreaction ... belongs to aggregated apis and are stored in the catalog not in etcd)
- Can't show any restorepoint (same as actions)
- You can still list the policy (They are CRD, stored in etcd)
- You can still list the profile (They are CRD, stored in etcd)


restart the catalog
```
kubectl -n kasten-io scale deploy boltdbweb --replicas 0
kubectl -n kasten-io scale deploy catalog-svc --replicas 1
```

Kasten is back to normal you can see restorepoints and actions again.

# Disaster recovery

With all that said you understand that catalog is a very important component that needs to be backed up regulary. That's the goal of the disater recovery policy.

You may notice that catalog has 2 containers.
```
kubectl -n kasten-io get deploy catalog-svc -o jsonpath='{.spec.template.spec.containers[*].name}'
```

The second container is kanister-sidecar. The kanister sidecar is able to use the data-mover kopia to protect the boltdb database. It back up the `model-store.db` file in the object location profile.

# catalog challenge 2

using the command
```
kubectl exec -it -n kasten-io deploy/catalog-svc -c catalog-svc -- ls -alh /mnt/
```

Write in the third line of catalog-challenge.txt the absolute path of the catalog file in the catalog-svc container that point to model-store.db.

# Aggregated API

A part of the API :
- BackupActions
- RestoreActions
- ExportActions
- RunActions
- RestorePoint
- RestorePointContent
are not stored in etcd but in the catalogs. The aggregated API service is here to serve them. Behind the hood when you request a backupaction to
kubenetes, kubenetes proxy your request to the aggreagated API.

This was made because the number of actions could become really important and etcd was not designed for handling so many datas (some of our customers may have a 200 GB catalog). Beside some query optimisation to quickly obtains the actions could not be obtained by using the kubernetes api.

List all backup action
```
kubectl get backupaction -A
```

Now scale down the aggregated API service and redo the request
```
kubectl scale -n kasten-io deploy aggregatedapis-svc --replicas=0
kubectl get backupaction -A
```

You should have a message like this one
```
Error from server (ServiceUnavailable): the server is currently unable to handle the request (get backupactions.actions.kio.kasten.io)
```

But it's still possible to obtain the policies or the profiles.
```
kubectl get policies.config.kio.kasten.io -A
kubectl get profiles.config.kio.kasten.io -A
```

That's because Profile and Policy are CRD and as such are served directly by the kubernetes API and stored in ETCD database.

Scale back the service to comeback to normal.
```
kubectl scale -n kasten-io deploy aggregatedapis-svc --replicas=1
```

# Crypto service

Envelope encryption involves encrypting your data with a Data Encryption Key, then encrypting the Data Encryption Key with a root key.
This allows you to store, transfer and use encrypted data by encapsulating the data key in an envelope instead of decrypting/encrypting data directly.
Hence key management is much more simple and stay secure, the root key stay in kasten, but the decryption key are closed to the data they encrypt.

When data need to be decrypted they are sent to the crypto service which returns an unencrypted payload using envelope encryption.