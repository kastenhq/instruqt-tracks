---
slug: install-minio
id: cebvub5hr2df
type: challenge
title: Install minio S3
teaser: Install minio S3 and create a location profile
notes:
- type: text
  contents: |-
    in order to export our snapshots we emulate a S3 service by installing
    minio endpoint and create a bucket. We'll use the endpoint and bucket to create
    a location profile in Kasten K10.
    ## WARNING
    In production you won't do that, it would be "absurd" to put in the same cluster
    - the local snapshot (the one we do with CSI snapshot) and
    - the remote snapshot (the one we do by exporting to S3 location)
    If the cluster failed we'd loose both of them. But for the need of the lab this is handful.
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
timelimit: 600
---

# Install Minio with helm chart
```
helm repo add minio https://helm.min.io/

kubectl create ns minio
helm install kasten-minio minio/minio --namespace=minio --version 8.0.10 \
  --set persistence.size=5Gi
# wait until mino is up and running.
kubectl get po -n minio -w
```

# Expose minio with nodeport

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: minio-nodeport
  namespace: minio
spec:
  selector:
    app: minio
    release: kasten-minio
  ports:
  - name: http
    port: 9000
    nodePort: 32010
  type: NodePort
EOF
```

# Create a kasten bucket

Open the minio tab and use this access and secret key to login

```
ACCESS_KEY=$(kubectl -n minio get secret kasten-minio -o jsonpath="{.data.accesskey}" | base64 --decode)
echo "Access key $ACCESS_KEY"
SECRET_KEY=$(kubectl -n minio get secret kasten-minio -o jsonpath="{.data.secretkey}" | base64 --decode)
echo "Secret Key : $SECRET_KEY"
```

Once logged create a kasten bucket.

# Create a location profile in Kasten

Go to Kasten > Setting > Create Location profile > S3 compatible

Use :
  *  name=kasten-bucket
  *  accesskey
  ```
  echo $ACCESS_KEY
  ```
  *  secretkey
  ```
  echo $SECRET_KEY
  ```
  *  endpoint
  ```
  echo http://$HOSTNAME.$INSTRUQT_PARTICIPANT_ID.instruqt.io:32010
  ```
  *  bucket=kasten
  *  leave other options with default value


