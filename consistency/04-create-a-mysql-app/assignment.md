---
slug: create-a-mysql-app
id: jcznjz30ndco
type: challenge
title: Create a basic mysql App
teaser: Let's create a basic mysql app with a statefulset so that we can exercice
  Kanister and Kasten.
notes:
- type: text
  contents: |-
    # Create a basic mysql app
    In this step we're going to create a very simple mysql application. We choose deliberatly
    simplicity so that it's easy to make the link between the mysql deployment and the
    Kanister configuration
- type: text
  contents: |-
    The mysql app is made of
    - One statefulset of one replicas, the mysql root password is passed as an env variable (ultrasecurepassword)
    - One PVC created by the statefulset
    - One service to access the mysql pod on port 3306
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
timelimit: 1200
---



# Create a mysql app

```
kubectl create namespace mysql
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  serviceName: mysql
  replicas: 1
  template:
    metadata:
      labels:
        app: mysql
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - name: mysql
        image: mysql:8.0.26
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: ultrasecurepassword
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      # storageClassName: basic
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: mysql
  name: mysql
  namespace: mysql
spec:
  ports:
  - name: "3306"
    port: 3306
    protocol: TCP
    targetPort: 3306
  selector:
    app: mysql
  type: ClusterIP
EOF
```

Wait for mysql to be ready.
```
watch kubectl get po -n mysql
```


## Now create some data

Create a mysql client
```
kubectl run mysql-client --restart=Never --rm -it --image=mysql:8.0.26 -n mysql -- bash
```
Connect to the server
```
mysql --user=root --password=ultrasecurepassword -h mysql
```
Create database and data
```
CREATE DATABASE test;
USE test;
CREATE TABLE pets (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE);
INSERT INTO pets VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);
SELECT * FROM pets;
exit
```

Exit the pods
```
exit
```


# Create a backup

Use Kasten to create a on-demand policy on this namespace and run it once.
![On demand policy](../assets/on-demand.png)


Notice the content of the restorepoint you can see mysql-0 volumes.
![Snapshot](../assets/snapshot-mysql.png)


Check the volumesnapshot also on the mysql namespace you see that one volumesnapshot was created

```
kubectl get volumesnapshot -n mysql
```



