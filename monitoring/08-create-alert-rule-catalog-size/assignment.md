---
slug: create-alert-rule-catalog-size
id: eo0ygx642tq8
type: challenge
title: Add another rule
teaser: This time it's your turn to implement your own rule on the catalog size
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
- title: K10 prometheus
  type: service
  hostname: k8svm
  path: /k10/prometheus/graph
  port: 32000
- title: Minio Dashboard
  type: service
  hostname: k8svm
  path: /
  port: 32010
difficulty: basic
timelimit: 1200
---
# Why the catalog size ?

Monitoring the catalog size is really important because each time
you upgrade a copy of the database is made and schema upgrade is
applied on this copy.

If the catalog is bigger than 50% of its PVC size the copy operation
will fail and upgrade won't be possible.

Hence We must track that the catalog size is never over the 50 % of
the PVC size.

# Create an alert if catalog size is over the 50 %

It's your turn now, create an alert that triggers a mail if we
pass the 50 % of the catalog PVC.

Do it as a new panel in the alert dashboard.

Tip: This percentage is already present on the already existing k10 dashboard.

