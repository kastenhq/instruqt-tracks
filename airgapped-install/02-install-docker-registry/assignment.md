---
slug: install-docker-registry
id: qkwyz7cg59s2
type: challenge
title: Install an internal docker registry
teaser: In order to install Kasten without an internet connection, you need an internal
  docker registry to pull the Kasten images.
tabs:
- title: Terminal nfs
  type: terminal
  hostname: nfs
- title: Terminal k8s
  type: terminal
  hostname: k8svm
difficulty: basic
timelimit: 2000
---

# Install the internal registry on nfs

On nfs let's create an internal registry with a basic credential testuser/testpassword

```
mkdir auth
docker run \
   --entrypoint htpasswd \
   httpd:2 -Bbn testuser testpassword > auth/htpasswd

docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v "$(pwd)"/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2
```

# Configure docker on k8s to accept this insecure registry


**WARNING**
execute this command on k8s machine not on nfs machine !


on k8s add this registry in the allowed insecure registry and reload docker
```

cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries": ["nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000"]
}
EOF

systemctl daemon-reload
systemctl restart docker
```

# Test that you can pull and push an image to this registry from k8s

on k8s
```
docker pull alpine
docker tag alpine nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000/alpine
```

check your images
```
docker images
```

Now connect to the regystry
```
docker login nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000 -u testuser -p testpassword
```

If login is successful you can push
```
docker push nfs.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000/alpine
```

