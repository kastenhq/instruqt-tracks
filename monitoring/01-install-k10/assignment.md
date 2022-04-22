---
slug: install-k10
id: xwndppoevgna
type: challenge
title: Install K10
teaser: Install K10 and Configure Storage
notes:
- type: text
  contents: |-
    # Understand how monitoring work in Kasten
    Kasten is made of many microservices that are interacting with each other.
    This topic has been covered in the track internal technical architecture of Kasten.
    ##
    Each component expose metrics, that make them observable.
- type: text
  contents: |-
    # Collect and visualize the Kasten metrics
    A component like prometheus can be used to collect those metrics and retain them
    for a certain duration. Prometheus is the metrics database.
    ##
    But contrary to classic database, prometheus execute active scraping of the metrics.
    Actually Prometheus support both mode : pull (scraping) or push but in Kasten we only use
    scraping, the pull mode.
- type: text
  contents: '![Monitoring architecture](../assets/monitoring.drawio.png)'
- type: text
  contents: |-
    # What we'll study

    We'll work on :
    - understanding the metrics
    - Creating useful custom promql request
    - explore the existing grafana dashboard
    - Set up our own dashboard
    - Create custom alerts on failed backup and catalog storage treshold both by mails and by sending message in a slack channel

    To create a complete environment let's create a complete Kasten environment.
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
difficulty: basic
timelimit: 1500
---
# Install Kasten K10

```console
helm repo add kasten https://charts.kasten.io/
helm repo update

kubectl create ns kasten-io

# install a lab licence
kubectl create -f license-secret.yaml

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