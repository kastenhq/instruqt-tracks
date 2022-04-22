---
slug: deeep-dive-k10-service-gui
id: rxmhbk10chqh
type: challenge
title: The GUI
teaser: Understand the different components involved when you're viewing the k10 Dashboard.
  You'll understand how the request are authenticated, how they are routed to the
  different services, how the dahsboard is built.
notes:
- type: text
  contents: |-
    We're going on this session to detail the dashboard and
    the component that are tightly connected to the dashboard. These
    microservices compose the GUI, and give to the end user a very efficient
    way to execute his backup, restore and migrate operations.
- type: text
  contents: |-
    # Composition of the architecture
    we identify 4 big components made themselves of microservices
    - API : catalog, aggregatedapi, crypto
    - **GUI : gateway, auth, frontend, dashboardbff, state**
    - Execution : config, jobs, executor, kanister
    - Monitoring : logging, prometheus, grafana, metering
- type: text
  contents: |-
    This session details the GUI part of the architecture:
    - gateway
    - auth
    - frontend
    - dashboardbff
    - state
    These microservices are responsible for managing access and display of the GUI as the communication of the GUI with the rest
    of the architecture.
- type: text
  contents: '![architecture components](../assets/architecture-components-gui.png)'
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
- title: Ambassador diagnostic endpoint
  type: service
  hostname: k8svm
  path: /ambassador/v0/diag
  port: 32030
difficulty: basic
timelimit: 300
---

# Understand the request flow

For handling a request 4 component are involved :
-  Gateway
-  Auth
-  Frontend
-  Dashboardbff

Let's understand how they work together

## Gateway

Gateway is based on the project [ambassador](https://www.getambassador.io). Gateway configure itself through the annotation in
services inside the kasten-io namespace.

Gateway is like an internal router, all requests to the dashboard go through it, depending of the prefix of the url
gateway will redirect the request to a given service.

Our gateway instance has an [AuthService](https://www.getambassador.io/docs/edge-stack/latest/topics/running/services/auth-service/).
```
kubectl get svc -n kasten-io gateway -o jsonpath='{.metadata.annotations.getambassador\.io\/config}'
```

You should see something like this
```
---
apiVersion: ambassador/v1
kind:  AuthService
name:  authentication
auth_service: "auth-svc:8000"
path_prefix: "/v0/authz"
allowed_request_headers:
- "x-forwarded-access-token"
---
apiVersion: ambassador/v1
kind:  Module
name:  ambassador
config:
  service_port: 8000
```

[AuthService](https://www.getambassador.io/docs/edge-stack/latest/topics/running/services/auth-service/) configures Ambassador to use an external service to check authentication and authorization for incoming requests. Each incoming request is authenticated before routing to its destination.

We'll experiment soon what happens when we desactivate auth.

### Checking the state and the route table of Ambassador

When you need to quickly understand the configuration of Ambassador you can use it's `/ambassador/v0/diag` endpoint.

Let's create the gateway diagnostic service nodeport.

```
cat <<EOF |kubectl -n kasten-io create -f -
apiVersion: v1
kind: Service
metadata:
  name: gateway-diag-nodeport
spec:
  selector:
    component: gateway
  ports:
  - name: http
    port: 8877
    nodePort: 32030
  type: NodePort
EOF
```

And now open the Ambassador diagnostic endpoint tab. You can ignore the warnings message about CRD because we use annotations
on the service itself instead of a Custom Resource Definition to configure Gateway.

## Ambassasor challenge

Go now to the Ambassador Route Table and find out the mapping to the prometheus service.

If
```
echo https://$HOSTNAME-32000-$INSTRUQT_PARTICIPANT_ID.env.play.instruqt.com/
```
Is the external url for the gateway service then the external url of the `frontend` is

```
echo https://$HOSTNAME-32000-$INSTRUQT_PARTICIPANT_ID.env.play.instruqt.com/k10/
```

This is consistent with what you see in the Ambassador Route Table. Open this url in another browser tab.

Knowing that the GUI endpoint of Prometheus is `/graph` write in the file `/root/ambassador-challenge.txt` the external url
of the prometheus GUI. Validate your result by testing this Url, check you obtain the prometheus GUI.


## Auth

Auth is the authentication module, all requests are validated by the AuthService. This module is highly configurable and better
described in the security track.

In the installation we did not setup auth option. Auth is configured with the default
value which is `No Authentication` and always validates the request, it acts as a simple `pass through`.

Let's scale down the auth service

```
kubectl scale -n kasten-io deploy auth-svc --replicas=0
```

And reload the kasten dashboard, you get a 403 answer.

If you check  the logs of the gateway you get also a 403 (Unauthorized) message in the logs

```
kubectl logs -l component=gateway -n kasten-io |grep 403
```

you should see something like

```
ACCESS [2022-01-25T08:59:32.437Z] "GET /k10/ HTTP/1.1" 403 UAEX 0 0 0 - "10.244.0.1" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36" "dd629542-3ddb-4690-8a13-db9f142a362f" "localhost:32000" "-"
```

you need to scale up back the auth module to comeback to normal.

```
kubectl scale -n kasten-io deploy auth-svc --replicas=1
```

Hence even if auth service is acting as a pass through (no auth configured) it's needed to have gateway to forward your request.

## Frontend and dasboardbff

Let's comeback to the Ambassador Route Table where you can see that the path

```
/k10/
```

is mapped to the frontend service. Hence when you access `https://<my domain>/k10/#` it's the frontend service that is answering (proxied by the gateway service of course).

Frontend deliver the html and javascript content for building the dashboard, this service is nearly acting as a static site, the javascript which is loaded by your browser is doing request to the dashboardbff service.

Open another browser tab and use this adress
```
echo https://$HOSTNAME-32000-$INSTRUQT_PARTICIPANT_ID.env.play.instruqt.com/k10/#
```

Click left on the dashboard > Inspect element > Network.

And search for summary or actions request.

You can see that request are constantly sent to dashboardbff-svc service.

Exemple :
```
GET /k10/dashboardbff-svc/v0/actions/summary HTTP/1.1
Accept: application/json
```

Let's scale down the dashboardbff

```
kubectl scale -n kasten-io deploy dashboardbff-svc --replicas=0
```

Reload the GUI, you get the GUI but you have many warnings messages and also the GUI show zero applications and zero policies.

Scale back dashboardbff to comeback to normal

```
kubectl scale -n kasten-io deploy dashboardbff-svc --replicas=1
```

## Frontend challenge

Edit the file /root/frontend-challenge.txt remove the unaccurate sentences. You have a readonly copy 06-frontend-challenge-readonly.txt if you failed and need to retry.

## Other component related to the dashboard

- State act like a cache on top of the Kube APIs. As Kasten is requesting the Kube API permanently, it avoid to flood Kube APIs by re-using known data in the cache.
- Metering, Prometheus and Grafana will be covered in greater details in another lab about Monitoring and Alerting but they are also used in the dashboard to display metrics about Kasten.