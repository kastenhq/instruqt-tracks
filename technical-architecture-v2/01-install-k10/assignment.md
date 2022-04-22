---
slug: install-k10
id: ntlg8rcgzmu5
type: challenge
title: Install K10
teaser: Install K10 and Configure Storage
notes:
- type: text
  contents: |-
    # Unsderstand the technical architecture of Kasten
    Understanding the internal technical architecture of Kasten will give you strong
    troubleshooting capacity. In an ideal world, when everything is working smoothly
    you don't need to understand the internal architecture, but when issues arise this
    knowledge will be very useful. Beside it's an excellent execise to study in depth
    a cloud native architecture based on microservices.
- type: text
  contents: |-
    # Composition of the architecture
    we identify 4 big components made themselves of microservices
    - API : catalog, aggregatedapi, crypto
    - GUI : gateway, auth, frontend, dashboardbff, state
    - Execution : config, jobs, executor, kanister
    - Monitoring : logging, prometheus, grafana, metering
    Let's see a global diagram.
- type: text
  contents: '![architecture components](../assets/architecture-components.png)'
- type: text
  contents: |-
    # What we'll study
    This diagram may look overwhelming. But don't worry we're going to split things in
    consistent parts and you'll have a good understanding.

    We're going to focus on API, GUI and Execution. Monitoring will have a
    dedicated track. But for now let's setup our lab by installing Kasten !
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
difficulty: basic
timelimit: 1000
---
# Install Kasten K10

```console
helm repo add kasten https://charts.kasten.io/
helm repo update

kubectl create ns kasten-io

# install a lab licence
kubectl create -f /root/license-secret.yaml

helm install k10 kasten/k10 --namespace=kasten-io
```

To ensure that Kasten K10 is running, check the pod status to make sure they are all in the `Running` state:

```console
watch -n 2 "kubectl -n kasten-io get pods"
```

Once all pods have a Running status, hit `CTRL + C` to exit `watch`.

# Configure the Local Storage System

Once K10 is running, use the following commands to configure the local storage system.

```console
kubectl annotate volumesnapshotclass csi-hostpath-snapclass k10.kasten.io/is-snapshot-class=true
```