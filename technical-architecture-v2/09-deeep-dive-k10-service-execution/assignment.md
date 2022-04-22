---
slug: deeep-dive-k10-service-execution
id: vnjy3q3tymgs
type: challenge
title: The job execution
teaser: Understand the different components involved when a job is created and executed.
  This track will let you check on the right logs to understand what when wrong when
  a job failed.
notes:
- type: text
  contents: |-
    We're going on this session to detail the different service involved in the execution process.
    config, jobs, executors, kanister and how they interact with each others.
- type: text
  contents: |-
    # Composition of the architecture
    we identify 4 big components made themselves of microservices
    - API : catalog, aggregatedapi, crypto
    - GUI : gateway, auth, frontend, dashboardbff
    - **Execution : config, jobs, executor, kanister**
    - Monitoring : logging, prometheus, grafana, metering
- type: text
  contents: |-
    This session details the Execution part of the architecture:
    - config
    - jobs
    - executor
    - kanister
    These microservices are responsible for handling the execution of all the actions (backupactions, restoreactions, exportactions ...).
    Each time a backup or an export is on going, it's happening with them.
- type: text
  contents: '![architecture components](../assets/architecture-components-exec.png)'
tabs:
- title: Terminal
  type: terminal
  hostname: k8svm
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
difficulty: basic
timelimit: 1000
---
The service involved in the execution of the kasten actions are :
- config-svc which acts as a scheduler, it is responsible for creating jobs.
- jobs-svc is responsible of holding the different jobs, it acts as a job queue and provide job information
- executor-svc polls the job and execute them
- kanister-svc execute blueprint. Blueprint let you extends the behavior of Kasten for consistent or logical backup

# Jobs

Let's have a look to the jobs.

```
kubectl exec -it -n kasten-io deploy/jobs-svc -- ls /mnt/k10state/kasten-io/jobs/
```

We get 2 boltdb databases again
```
model-store.db  queue.db
```

- In model-store you will find the complete jobs description whether they are running, pending, completed or failed.
- In queue.db there is only a reference to jobs. If the reference is in the queue it means that the job is running or
  waiting to be run.

When a job is finished (Completed or failed), it is removed from the queue but kept in model-store.

# Executor

Executor poll the queue and execute no more than one job. If you want to increase the number of concurent job you need
to increase the number of executors.

Executor communicate with your infrastructure for the backup or with Kanister to execute the blueprint.

When job is finished executor remove the job from the queue.

# Experiment

Let's see what happen if for some reasons (like an intenal network issue) the jobs-svc service is not available or reachable.

```
kubectl -n kasten-io scale deploy jobs-svc --replicas 0
```
Go to the Kasten dashboard and lauch the policy execution by running once the mongodb policy.

You should get a popup displaying a 500 error


Let's see what's going on in the executors.

```
kubectl logs -c executor-svc -l component=executor -n kasten-io | grep "Error while polling for QueuedJob"
```

You can see that the action in the Kasten dashboard seems "stuck".

Scale back to normal

```
kubectl -n kasten-io scale deploy jobs-svc --replicas 1
```

# Blueprint and Kanister

Kanister is a framework to capture application specific data management tasks in blueprints which
can be easily shared and extended.

Kanister can :
- Execute actions before and after the snapshot (consistent backup)
- Replace completly the kasten backup operations (logical backup)

Kanister is already used by kasten for some of the operations kasten do like export or statistics.

```
kubectl logs -n kasten-io -l component=kanister --tail=10000 | grep -Eo '"Command":"kopia .*","'
```

You should see kopia command like
```
kopia repository connect
kopia snapshot create
kopia blob stats --raw
kopia snapshot list --all
```




We'll get more in depth on the next sessions especially when working with logical backup.