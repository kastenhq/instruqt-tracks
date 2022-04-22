---
slug: configure-keycloak
id: axncoagkaupf
type: challenge
title: Configure Keycloak
teaser: Create a keycloak instance in order to have an OIDC provider where you control
  user and group.
notes:
- type: text
  contents: |-
    Managing multitenancy involves two things :
    * defines role for each users or group of users
    * identify users

    Click on the right arrrow to have more details.
- type: text
  contents: |-
    We define role for each user through Kubernetes RBAC.

    Kasten ClusterRole and Role defines verb on Kasten API, like for instance `create` (verb) `backupaction` (kasten API).

    ClusterRoleBinding and RoleBinding bind user to ClusterRole and Role, like for instance `eric` has the ClusterRole `k10-admin`.

    If you need a better understanding of Kubernetes RBAC we strongly encourage you to read this [comprehensive guide](https://medium.com/devops-mojo/kubernetes-role-based-access-control-rbac-overview-introduction-rbac-with-kubernetes-what-is-2004d13195df)
- type: text
  contents: |-
    To identify user Kasten support different authentication schemes :
    * No authentication, often used with `kubectl port-forward` when you don't want to expose directly the kasten service
    * Basic Auth
    * Token auth (any token that can be verified by the Kubernetes server)
    * OIDC (Open ID Connect)
    * LDAP and Openshift which are indirectly using OIDC through the [DEX component](https://dexidp.io).

    Only Token Auth and OIDC allow us to identify more than one user and are applicable for multitenancy.
- type: text
  contents: |-
    On this track we'll concentrate on OIDC because it's a very well supported and adopted identification and authentication protocol

    If you need a better understanding of OIDC we strongly encourage you to read this [comprehensive guide](https://developer.okta.com/blog/2019/10/21/illustrated-guide-to-oauth-and-oidc).

    In the next image we'll show the sequence of events when a user accesses K10’s dashboard with an OIDC Provider.
- type: image
  url: https://blog.kasten.io/hs-fs/hubfs/Blog%20Images/OIDC/auth%20flow%20diagram.jpeg?width=1000&name=auth%20flow%20diagram.jpeg
- type: text
  contents: |-
    We're going to use [keycloak](https://www.keycloak.org) as an OIDC identity provider.
    ##
    Most of the time the deployment of the OIDC provider is not your preoccupation, and an OIDC provider is already present on premise
    (Keyclock, Pingidentity ...) or on the cloud (Azure Active Diretory, Okta, Google Connect ...).
    ##
    However how the OIDC provider has been configured is your preoccupation ! Mainly for understanding how the JWT token is built
    (what's the layout of the different claims or what other attributes could be leveraged), it's why this example configuration
    of Keyclock is important if you don't have a big experience on OIDC.
- type: text
  contents: |-
    Here we deploy keycloak on another machine outside of the kubernetes cluster, the deployment and configuration are easy and completly guided.
    However it's useful to understand the OIDC posibilities and how kasten interact with them.
tabs:
- title: Terminal keycloak
  type: terminal
  hostname: keycloak
- title: Terminal k8s
  type: terminal
  hostname: k8svm
difficulty: basic
timelimit: 1200
---

# Let's create a keycloak instance

Use the keycloak terminal to lauch keycloak
```
docker run -d --name=keycloak -p 8080:8080 -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=admin quay.io/keycloak/keycloak:16.1.1
```

Wait few seconds that keycloak finish starting.
You can control that by searching the sentence `Admin console listening on http://127.0.0.1:9990` in the logs.

```
docker logs keycloak -f
```

Use Ctrl-C to get out of the logs.

Once keycloak started let's configure keycloak to accept non https protocol, securing the OIDC provider is not the objective
of this track and we take here the shortest path.

```
docker exec -it keycloak bash
```

Change the configuration of the master realm.
```
cd /opt/jboss/keycloak/bin/
./kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin
```
Password is admin.

Now set up the configuration
```
./kcadm.sh update realms/master -s sslRequired=NONE
exit
```

You can now open a browser tab to the keycloak url
```
echo http://keycloak.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:8080/
```

and click on the administraion console link.

The login and password were setup in the docker command it's admin/admin.

# Create the my-company realm

We create a new realm call "my-company"

![New realm my-company](../assets/add-realm.png)

Make sure this realm has also SSL not required

![disable SSL for realm my-company](../assets/add-realm-disable-ssl.png)

## Create a k10admin group and a user in this group

Create an admin group k10admin (we'll add other group later)

![Create k10admin group](../assets/add-admin-group.png)

Create the user michael belonging to the k10admingroup. Make sure it has his email verified.

![Create michael](../assets/add-user.png)

Setup the password as michael (same as username for simplicity but feel free to use something else).
Turn off temporary.

![Setup password](../assets/add-user-password.png)

Make sure it has his email verified

![Check email verified](../assets/add-user-email-verified.png)

## Create a kasten client in the realm

Create a kasten client in the realm my-company.
Make sure the client is Enabled.

![Create a kasten client](../assets/add-client.png)

Make sure this client is confidential and accept implicit flow (implicit flow is needed for using oidcdebugger)

![kasten client, confidential and accept implicit flow](../assets/add-client-confidential-implicit.png)

On the allowed redirect add
- https://oidcdebugger.com/debug
- the url of the k10 oidc redirect endpoint (even if kasten has not been created we know what will be the URL)
```
echo http://k8svm.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:32000/k10/auth-svc/v0/oidc/redirect
```

![kasten client, redirects](../assets/add-client-redirects.png)

To add the groups in the JWT token add the group mapper,
- Disable Full group path.
- For name choose what you want (ie group-mapper)
- For Token Claim Name choose `groups`

![kasten client, add the group mapper](../assets/add-client-group-mapper.png)


# Let see what will be the JWT token returned by keycloak

In a new browser tab go to https://oidcdebugger.com/  use

```
curl http://keycloak.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:8080/auth/realms/my-company/.well-known/openid-configuration | jq '.authorization_endpoint'
```

to fill up the field form

![Fill up the form](../assets/oidc-debugger.png)

Then click send and connect as michael/michael

You should be redirected to oidc-debugger with the content of the JWT Token

```
{
   "exp": 1644490827,
   "iat": 1644490527,
   "auth_time": 1644490072,
   "jti": "1857a3b2-ada4-4b21-8449-c058e88a3601",
   "iss": "http://keycloak.5vubxfv1zp9p.instruqt.io:8080/auth/realms/my-company",
   "aud": "kasten",
   "sub": "aa30b2a9-cd13-42d0-baec-449434921d33",
   "typ": "ID",
   "azp": "kasten",
   "nonce": "ornkyd457rq",
   "session_state": "9d014d1d-170f-48f1-907f-0824339bc04d",
   "c_hash": "NhhY4mDF9yaZjl9qu7Gaxw",
   "acr": "0",
   "sid": "9d014d1d-170f-48f1-907f-0824339bc04d",
   "email_verified": true,
   "preferred_username": "michael",
   "groups": [
      "k10admin"
   ]
}
```

Congratulation your keycloak configuration is successful.

# More user and groups

Now in keycloak in the my-company realms create 3 groups dev, test and prod

And those users :

*  dev-user1/dev6v3p9gy, dev-user2/dev6v3p9gy, dev-user3/dev6v3p9gy belonging to the dev group
*  test-user1/test6v3p9gy, test-user2/test6v3p9gy, test-user3/test6v3p9gy belonging to the test group
*  prod-user1/prod6v3p9gy, prod-user2/prod6v3p9gy, prod-user3/prod6v3p9gy belonging to the prod group
*  devops-user1/devops6v3p9gy belonging to the dev, test and prod group

We'll use them latter when testing with RBAC.