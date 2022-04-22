---
slug: kanister-kasten-mysql-consistent
id: aoago6zo3as4
type: challenge
title: Create an application consistent backup for mysql
teaser: Logical backup are simple and straightforward however they are not incremental,
  each time you need to export the whole dump. Let's see how we can use best of both
  word incremental and consistent backup.
notes:
- type: text
  contents: |-
    # Application consistent backup
    Kasten also support application consistent backup, in this case we do not override the backup
    of a PVC with the backup of a locical artifact but rather we ensure that before
    snapshoting the filesystem is in a consistent state.
- type: text
  contents: |-
    ### App consistent backup
    ![With consistet blueprint](../assets/blueprint-app-consistent-app-consistent.drawio.png)
- type: text
  contents: |-
    In the previous image we call pg_start_backup before the snap and pg_stop after the snap.
    For mongo we call fsyncLock before the snap and fsyncUnlock after the snap.
    ##
    In the case of mysql we're going to call `FLUSH TABLES WITH READ LOCK` before the snap
    and `UNLOCK TABLES` after the snap.
- type: text
  contents: |-
    Kasten will execute the consistent blueprint if it finds for action name
    - `backupPrehook` Before it snapshots the PVC attached to the workload
    - `backupPosthook` After it snapshots the PVC attached to the workload
- type: text
  contents: |-
    # Best of both words ?
    This solution look better than the logical backup because we are snapshotting a PVC as usual.
    This provides now incremental and consistent backup beside we have fast local recovery (because we re-produce local PVC snapshots).
    The blueprint is also often much simpler.
    ##
    It sounds like best of both worlds ?
    ##
    However we'll see in greater details that even if it's most of the time the best solutions there "could be" some caveat.
    ##
    This "flush & lock"  pattern can block your database, you have to take that in account and go for more sophisticated blueprints if your database can run very long transaction.
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
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
timelimit: 1800
---

[FLUSH TABLES WITH READ LOCK ](https://dev.mysql.com/doc/refman/8.0/en/flush.html#flush-tables-with-read-lock)
closes all open tables and locks all tables for all databases with a global read lock.

This operation is a very convenient way to get backups if you have a file system that can take snapshots in time. Use UNLOCK TABLES to release the lock.

## This solution however has a Caveat

FLUSH TABLES WITH READ LOCK ensure that the backup is consistent. But FLUSH TABLES WITH READ LOCK can be run even though there may be a running query that has been executing for hours.

In this case, everything is locked in the Waiting for table flush. Killing the FLUSH TABLES WITH READ LOCK does not correct this problem. The only way to get the server operating normally again is to kill off the long running queries that blocked it to begin with. This means that if there are long running queries FLUSH TABLES WITH READ LOCK can get stuck, leaving server in read-only mode until waiting for these queries to complete.

If you think that can happen you'll have to elaborate a more sophisticated blueprint that make sure long running transactions are finished before engaging the FLUSH TABLES WITH READ LOCK.

# Understand the solution we are going to setup

To understand the solution we're going to setup we have provided you with 2 terminals on the first terminal
connect to the database :

```
kubectl run mysql-client-1 --restart=Never --rm -it --image=mysql:8.0.26 -n mysql -- bash
```
Connect to the server
```
mysql --user=root --password=ultrasecurepassword -h mysql
```

Issue the command
```
FLUSH TABLES WITH READ LOCK;
```

On the second terminal also connect to the database though another seesion using a second mysql client pod

```
kubectl run mysql-client-2 --restart=Never --rm -it --image=mysql:8.0.26 -n mysql -- bash
```
Connect to the server
```
mysql --user=root --password=ultrasecurepassword -h mysql
```

Try to insert a line
```
use test;
INSERT INTO pets VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);
```

You should see that the command is blocking waiting for the global unlock.

On the first terminal run
```
show full processlist;
```

You should see that your insert statement is awaiting for the global lock.

Now run the request on the first terminal to release the lock.

```
UNLOCK TABLES;
```

And on the second terminal you see your insert statement has returned. It's because the lock was released.

On the first terminal exit the mysql command line and instead run this command line in the pod

```
exit
mysql --user=root --password=ultrasecurepassword -h mysql --execute="FLUSH TABLES WITH READ LOCK; select sleep(20);"
```

On the second terminal try again to insert a line
```
INSERT INTO pets VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);
```

The insert is waiting but after 20 seconds the `select sleep(20)`command return and the session is killed which release automatically the lock.

We have now a strategy for the consistent backup !

# Build a flush-and-lock deployment

We're going to build a flush-and-lock deployment, the blueprint will scale up this deployment before the snapshot
and scale it down after the snapshot, releasing any lock.

Leave the pod by typing `exit` in the first terminal.

```
cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: flush-and-lock
  name: flush-and-lock
  namespace: mysql
spec:
  replicas: 0
  selector:
    matchLabels:
      app: flush-and-lock
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: flush-and-lock
    spec:
      containers:
      - image: mysql:8.0.26
        name: mysql
        resources: {}
        command:
        - sh
        - -o
        - errexit
        - -c
        - |
          mysql --user=root --password=ultrasecurepassword -h mysql --execute="FLUSH TABLES WITH READ LOCK; select sleep(3600);"
status: {}
EOF
```

For the moment this deployment is scaled to zero, hence no action will happen.

As a test scale it up
```
kubectl scale deploy flush-and-lock -n mysql --replicas=1
```

Wait for the flush-and-lock pod to be up and running.

On the open mysql session in the second terminal try again to insert a line
```
INSERT INTO pets VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);
```

You notice that this blueprint flush with a read lock and sleep for 3600 seconds (1 hour). But when the deployment will be scaled down by the blueprint, the mysql session will be killed and the locked released.

Let's scale it down.
```
kubectl scale deploy flush-and-lock -n mysql --replicas=1
```

That will return the insert statement in the second terminal.


Now we can write the consistent blueprint

# Consistent blueprint

```
cat <<EOF > mysql-hooks.yaml
apiVersion: cr.kanister.io/v1alpha1
kind: Blueprint
metadata:
  name: mysql-hooks
  namespace: kasten-io
actions:
  backupPrehook:
    phases:
    - func: ScaleWorkload
      name: scaleUpFlushAndLock
      args:
        namespace: '{{ index .Object.metadata "namespace" | toString  }}'
        kind: 'deployment'
        replicas: 1
        name: 'flush-and-lock'
  backupPosthook:
    phases:
    - func: ScaleWorkload
      name: scaleDownFlushAndLock
      args:
        namespace: '{{ index .Object.metadata "namespace" | toString  }}'
        kind: 'deployment'
        replicas: 0
        name: 'flush-and-lock'
EOF
```

Notice that this blueprint is much simpler. It's also using a convenient function of the
kanister framework : [ScaleWorkload](https://docs.kanister.io/functions.html#scaleworkload)

Before the snapshot we scale up the flush-and-lock deployment in order to trigger a flush and lock.

When the snapshot is over we scale it down, releasing in the same time the lock and letting
the other write operation in pending state to finish.

Apply it

```
kubectl create -f mysql-hooks.yaml
kubectl --namespace mysql annotate statefulset/mysql kanister.kasten.io/blueprint=mysql-hooks --overwrite
```

Now relaunch the mysql-backup policy. You should see new snapshots in the mysql namespaces.

You have now the garantee that the backup is consistent.

When you run a backup check the pods you'll see the flush-and-lock pod going up and down.

```
kubectl get po -n mysql -w
```

You can also check that now you have again volume snapshots

```
kubectl get volumesnapshot -n mysql
```

But this time you have the garantee that they are in a consistent state.









