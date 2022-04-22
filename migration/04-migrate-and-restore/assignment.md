---
slug: migrate-and-restore
id: wusdeksbfb5g
type: challenge
title: Migrate the restore point to the datacenter east cluster
teaser: In this challenge we're going to migrate the restorepoint point created by
  the previous step from datacenter west to datacenter east.
notes:
- type: text
  contents: |-
    In this challenge we're going to migrate the restorepoint point created by the previous step from datacenter west to datacenter east.

    This migration process is also driven by a policy.
- type: text
  contents: |-
    In the policy you can define to just migrate the restorepoint or migrate the restorepoint plus trigger the restoration of the application.

    In this challenge we're going to just migrate the restore points first then restoration will be handled in a second step.
tabs:
- title: Term K10 West
  type: terminal
  hostname: k8svm
- title: Term K10 East
  type: terminal
  hostname: k8svmdr
- title: Minio
  type: website
  url: http://minio.${_SANDBOX_ID}.instruqt.io:9001
  new_window: true
- title: K10 West
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
- title: K10 East
  type: service
  hostname: k8svmdr
  path: /k10/#
  port: 32000
difficulty: basic
timelimit: 1200
---

# Obtain the migration token from the soucer cluster (datacenter west)

In the k10 west tab use the import details on the policy that you just created.

Click on copy to save this value in you clipboard.

![Migration token](../assets/migration-token.png)

This migration token contains 2 main elements :
- the path to your restorepoints on the location profile (here minio)
- the encryption keys used by kopia (the datamover) for encrypting the data on the location profile

# Create an import policy on destination cluster (datacenter east)

WARNING : the rest of the actions in this challenge are now on *datacenter east*, both dasboard and command line.

On the k10 east tab create an import policy (use the same policy than the backup policy in datacenter west)

![Import policy](../assets/import-app-with-backup-true.png)

Paste the migration token.

![Paste migration token](../assets/paste-migration-token.png)

Automatically Kasten select the location profile that has the same attribute than the location profile defined on the source cluster (datacenter west).

Create it and run it once. This should not take long because we just import restore point.

![Import policy not long](../assets/import-policy-not-long.png)

# Use the restorepoint to restore the applications

Still in the destination cluster go in applications > deleted you should see mysql and mongodb.

![Deleted apps](../assets/deleted-app.png)

They appear as deleted in the dashboard because their restorepoint exist but not their namespaces.

Choose the mysql restore point

![Choose mysql](../assets/choose-mysql.png)

and click restore.

![Click restore](../assets/click-restore.png)

Do the same thing with mongodb.

On the dashborad you should see the thow restore action on going.

![Restore on going](../assets/restore-on-going.png)

# Verify data are also restored

## Check Mysql
Create a mysql client
```
kubectl run mysql-client --restart=Never --rm -it --image=mysql:8.0.26 -n mysql -- bash
```
Connect to the server
```
mysql --user=root --password=ultrasecurepassword -h mysql
```
Check the database test
```
USE test;
SELECT * FROM pets;
exit
```

Exit the pods
```
exit
```

## Check Mongo
Run a mongo client
```console
export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace mongodb mongo-mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 --decode)
kubectl run --namespace mongodb mongo-mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image docker.io/bitnami/mongodb:4.4.11-debian-10-r12 --command -- mongo admin --host "mongo-mongodb-0.mongo-mongodb-headless:27017,mongo-mongodb-1.mongo-mongodb-headless:27017" --authenticationDatabase admin -u root -p $MONGODB_ROOT_PASSWORD
```

Verify the log collection
```
db.log.find()
```

When all seems good you can exit
```
exit
```