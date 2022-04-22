---
slug: kanister-kasten-mysql-dump
id: fjkaciqbiczw
type: challenge
title: Use mysql blueprint with Kasten
teaser: Kasten can leverage Kanister to execute blueprint, we'll see that this is
  something very simple to implement.
notes:
- type: text
  contents: |-
    Kasten can leverage Kanister to execute blueprint, we'll see that this is
    something very simple to implement and something we want badly actually.
    ###
    Indeed Kanister let us capture complex domains operations in blueprint and make them shareable
    and extendable. However it's still a manual process to launch an actionset, There is no support
    for scheduling, monitoring and foremost we also want to capture the whole state of the applications
    in the same time we run the blueprint.
- type: text
  contents: |-
    ### Logical backup
    ![With logical blueprint](../assets/blueprint-logical-logical.drawio.png)
- type: text
  contents: |-
    All you have to do is to annotate the object to indeicate the blueprint that kasten must apply
    ```
    kanister.kasten.io/blueprint=<your blueprint>
    ```
    For instance
    ```
    kanister.kasten.io/blueprint=mysql-blueprint
    ```
- type: text
  contents: |-
    At this point it's Kasten who will be creating the Actionset for you.
    ##
    however Kasten will execute only if it finds for action name
    - `backup` when it creates a restorepoint
    - `restore` when it restores a restorepoint
    - `delete` when it deletes a restorepoint
    Other action name will be ignored.
- type: text
  contents: |-
    ## WARNING
    This solution overide the backup of the PVC (which means that there is not anymore a Volume backup).
    Beside each backup is not incremental anymore, it's a new dump each time.
    If your database is not too big (under 30 Go) that can be ok depending of your RPO requirement.
    ##
    However if your database is huge (for intsance a 1 To database), sending a 1To dump over the network
    and create a 1To room on your S3 bucket at each backup won't work most of the time. If you are in this situation
    you'll need a app consistent blueprint, but we'll see that in the last challenge.
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
timelimit: 1800
---

# Let Kasten create the actionset for you

Previously we created an actionset manually. What we want is having Kasten
do it each time it backups the mysql namespace.

The only thing to do is to annotate the statefulset with an annotation that indicate the blueprint to apply.

```
kubectl --namespace mysql annotate statefulset/mysql kanister.kasten.io/blueprint=mysql-blueprint
```

Now each time Kasten backup, restore or delete a restorepoint it will also create an actionset.

- The value of the annotation become the `--blueprint` option in `kanctl`command
- The object annotated replace the `--statefulset` option in `kanctl`command
- the action is backup, restore or delete depending of your action on the restorepoint
- The kanister profile will be created from the Kasten profile you indicate in your policy or backup action

# Backup with Kasten

Go on the Kasten dashboard and run once again the policy.

You must observe that a kanister pod execute. It's executing the backup action.

Check on minio that now you have a new dump. Notice that now the dump are
automatically put in the cluster folder

```
ACCESS_KEY=$(kubectl -n minio get secret kasten-minio -o jsonpath="{.data.accesskey}" | base64 --decode)
echo $ACCESS_KEY
SECRET_KEY=$(kubectl -n minio get secret kasten-minio -o jsonpath="{.data.secretkey}" | base64 --decode)
echo $SECRET_KEY
```

![In the cluster folder](../assets/in-the-cluster-folder.png)

Now go to the restore point you can see that no volume is present
![No volumes](../assets/no-volumes.png)
because it's been replaced by the dump.

![Kanister artifact](../assets/kanister-artifact.png)

Notice also that no extra volumesnapshot has been created on the mysql namespace.
```
kubectl -n mysql get volumesnapshot
```

All that was possible because we use the name `backup`, `restore` and `delete` for the actions in the blueprint.

Kasten execute them when it backup, restore or delete. If your actions had others names they won't be called by Kasten.

# Restore with Kasten

Now restore in another namespace (mysql-restored) with Kasten:

![Restore in another namespace](../assets/restore-in-another-ns.png)

During the restoration process you must observe that a kanister pod execute when mysql-0 pod is up and running. It's executing the restore action.

```
while true; do kubectl logs -f -n mysql-restored -l createdBy=kanister; sleep 2; done
```

Check the content of your database. The test database should be there.

Enter mysql pod
```
kubectl run mysql-client --restart=Never --rm -it --image=mysql:8.0.26 -n mysql-restored -- bash
```


Connect to the server
```
mysql --user=root --password=ultrasecurepassword -h mysql
```

Check test databases is there
```
show databases;
```

# Delete a restore point

Also delete a restorepoint using the Kasten Dashboard and verify the corresponding dump is deleted

![Delete restorepoint](../assets/delete-restore-point.png)

Check the retireaction is successful

![Retire action](../assets/retire-action.png)

And check also on minio that the corresponding dump folder is gone.