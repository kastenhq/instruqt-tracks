---
slug: create-a-kasten-admin
id: 1gwd5kadf30f
type: challenge
title: Create a Kasten Admin
teaser: Use the built in ClusterRole to make the identified user a Kasten Administrator
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

# Identify built-in cluster role

When you install kasten it comes with built in Kasten ClusterRole.
You can attach a ClusterRole
*  in a ClusterRoleBinding (which is not a namespaced object) and in this case the role is applied for the user in all the namespaces
*  in a RoleBinding (which is a namespaced object) and in this case the role is applied for the user only in this namespace
List all the built in ClusterRole brought during Kasten installation

```console
kubectl get clusterrole |grep k10
```

List all the built in role in the kasten-io namespace brought during Kasten installation
```console
kubectl get role -n kasten-io
```

Those ClusterRole/Role are described in the [kasten RBAC documentation](https://docs.kasten.io/latest/access/rbac.html).

# Give michael the k10-admin role on all the namespaces

michael belongs to the group k10admin, let's see if the group `k10admin` can create a backupaction in any namespace ?

```console
kubectl auth can-i create backupactions.actions.kio.kasten.io --as=michael --as-group=k10admin --all-namespaces
```

The answer should be no...

You must understand that each time the dashboard backend is acting on the API it's doing so the same
way we jus did it in this API call :

```
--as=michael --as-group=k10admin
```

But even if it's possible we don't want to set up a rolebinding at the user level because for big
organisations with many teams that would be very difficult to maintain. It's why we set it up at the
group level.

Let's apply a clusterrolebinding then

```console
kubectl create clusterrolebinding k10-admin-group-k10admin --clusterrole=k10-admin --group=k10admin
```

And now I can ask again my previous question

```
kubectl auth can-i create backupactions.actions.kio.kasten.io --as=michael --as-group=k10admin --all-namespaces
```

This time the answer is yes ! And you'll see a big change in the kasten dashboard as well. All the namespaces
are now available and if you check the  Settings > Support > Cluster information > View Current User Details
you can see that you can now perform all operations.

But you notice also that you constantly get this popup saying "K10 services are reporting errors". Actually
There is no errors but because you are k10-admin on all namespaces - kasten-io included, the dashboard impersonate
`k10admin` group to check the health of the kasten-io namespace.

But the k10-admin ClusterRole is only made for manipulating Kasten API not deployment or secret. So for this special
case we need to bind the local role kasten-ns-admin in the kasten-io namespace to the group k10admin :

```console
 kubectl create rolebinding k10-ns-admin-group-k10admin --role=k10-ns-admin --group=k10admin --namespace=kasten-io
```

Now with a user belonging to the k10admin group you have a working k10-admin among your users.

Let's check that michael is really able to use Kasten, create a policy for the `default` namespace with all the default option and run it once.
