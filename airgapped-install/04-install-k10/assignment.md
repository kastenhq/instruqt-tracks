---
slug: install-k10
id: ruohfmewxyyy
type: challenge
title: Install K10
teaser: Install K10 in airgapped mode with with NFS as a location profile and an internal
  registry to pull all the Kasten images.
tabs:
- title: Terminal k8s
  type: terminal
  hostname: k8svm
- title: Terminal nfs
  type: terminal
  hostname: nfs
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
difficulty: basic
timelimit: 1200
---
# Make sure all kasten images are pushed to the internal registries

This example is based on the 4.5.8 version of kasten, change the version number for the last recent version number.

In order to push all the kasten images in the internal images, Kasten feature the k10offline image that can do that for you.

This image is mounting you docker sock for retreiving the credentials to the internal registry (`-v ${HOME}/.docker:/root/.docker`).

```
docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock \
    -v ${HOME}/.docker:/root/.docker \
    gcr.io/kasten-images/k10offline:4.5.8 pull images --newrepo nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000/kasten-images
```

When working airgapped we won't have the chart available through internet, we need to download it first.

```
helm repo add kasten https://charts.kasten.io/
helm repo update && \
    helm fetch kasten/k10 --version=4.5.8
```

You should see k10-4.5.8.tgz archive in you directory now.

# Install Kasten K10

At this point you don't need anymore a network connection to the internet.

Everything can work airgapped.

install a lab licence
```
kubectl create -f /root/license-secret.yaml
```

# Install Kasten K10

```
helm install k10 k10-4.5.8.tgz --namespace=kasten-io \
--set global.airgapped.repository=nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000/kasten-images \
--set secrets.dockerConfig=$(base64 -w 0 < ${HOME}/.docker/config.json) \
--set global.imagePullSecret="k10-ecr"
```

To ensure that Kasten K10 is running, check the pod status to make sure they are all in the `Running` state:

```
watch -n 2 "kubectl -n kasten-io get pods"
```

Once all pods have a Running status, hit `CTRL + C` to exit `watch`.

# Check the images are all belonging to the internal registry

```
kubectl get po -n kasten-io -ojsonpath='{range .items[*].spec.containers[*]}{.image}{"\n"}{end}'|sort|uniq
```

You may notice has the layout is flat we add the k10 prefix on tag for non kasten images, this is to avoid images collisions.

# Expose the K10 dashboard

While not recommended for production environments, let's set up access to the K10 dashboard by creating a NodePort. Let's first create the configuration file for this:

```console
cat > k10-nodeport-svc.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: gateway-nodeport
  namespace: kasten-io
spec:
  selector:
    service: gateway
  ports:
  - name: http
    port: 8000
    nodePort: 32000
  type: NodePort
EOF
```

Now, let's create the actual NodePort Service

```console
kubectl apply -f k10-nodeport-svc.yaml
```
# View the K10 Dashboard

Once completed, you should be able to view the K10 dashboard in the other tab on the left.

# Use the NFS PVC as a location profile

Once K10 is running and accessible, go on kasten dashboard and create a nfs location profile using the pvc-nfs-kasten pvc.

Test by creating a policy with the export location profile you just created on the default namespace.

After successful policy execution, check the content of the `/nfs` directory in the nfs server. You should find a usual k10 layout.
