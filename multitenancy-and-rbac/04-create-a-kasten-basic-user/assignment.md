---
slug: create-a-kasten-basic-user
id: wn89mhotusl4
type: challenge
title: Create a Kasten basic user
teaser: Create a Kasten basic user with access to only his namespace for backup and
  restore operation
tabs:
- title: Terminal k8s
  type: terminal
  hostname: k8svm
- title: Terminal keycloak
  type: terminal
  hostname: keycloak
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
  new_window: true
difficulty: basic
timelimit: 1200
---

For the need of this tutorial let's create 3 namespaces

```
kubectl create ns development
kubectl create ns qualification
kubectl create ns production
```

Connect as dev-user1 for the moment you can't see any namespaces on the dasboard, specifically not on the development namespace.

 ```
 kubectl auth can-i create backupactions.actions.kio.kasten.io --as-group=dev --as=dev-user1 -n development
 ```

 The answer should be no.

You must understand that each time the dashboard backend is acting on the API it's doing so the same
way we jus did it in this API call :

```
--as=dev-user1 --as-group=dev
```

 We want to limit access for `dev-user1` to only the `development` namespace where he'll be able to perform backup and restore
 of this namespace.

 Check the content of the Role kasten-basic

 ```
 kubectl get clusterrole k10-basic -o yaml
 ```

 You can see the diffent action a basic-user can do particulary create BackupAction or RestoreAction.

 Let's dev-user1 be a basic-user on this namespace by acting on his group.

 ```
 kubectl create rolebinding k10-basic-group-dev --clusterrole=k10-basic --group=dev --namespace=development
 ```

 Now let check that alice can create backup action
 ```
 kubectl auth can-i create backupactions.actions.kio.kasten.io --as-group=dev --as=dev-user1 --namespace=development
 ```

 The answer should be yes this time.

 But if we ask the same question for qualification
```
 kubectl auth can-i create backupactions.actions.kio.kasten.io --as-group=dev --as=dev-user1 --namespace=qualification
 ```

The answer should be no, it's a namespace binding contrary to a cluster binding as we did for michael.

Go in the dashboard. You should see the development namespace and only the development namespace.

Try to perfom a backup by going to the application tile and click the "snapshot" button.

WARNING: Non k10-admin user can create policy on their own but won't have the right to run them manually,
only the scheduler will be able to run them.

 # challenge RBAC

 Now it's your turn, make the necessary operation for having test group able to perform
 k10-basic operations on qualification namespaces and prod group able to perform K10-basic
 operations on the production namespace.

 Check by connecting with
 - test-user1 you can only perform k10-basic operations on the qualification namespace
 - prod-user1 you can only perform k10-basic operations on the production namespace
 - devops-user1 you can perform k10-basic operation on the 3 namespaces : development, qualification and production