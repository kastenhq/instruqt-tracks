---
slug: configure-alert-channel-in-grafana
id: iox8p0ag2izw
type: challenge
title: Configure the alert channel in Grafana
teaser: Before creating alerts rule we need to setup an alert tool.
notes:
- type: text
  contents: |-
    Once you bring back your backup to normal you noticed that the metrics
    ```
    catalog_actions_count{type="backup",status="failed"}
    ```
    Don't change the value is still one.
- type: text
  contents: |-
    If we create an alert with
    ```
    catalog_actions_count{type="backup",status="failed"} > 0
    ```
    We'll always receive an alert.

    What we need is capture the variations of this value in a given time period.
- type: text
  contents: |-
    Beside we need to decide which alert tool we're going to use.
    The simplest approach is not to use alertmanager in prometheus but rather the
    alert module of Grafana who is more user friendly.
    ##
    For the simplicity of this track and because we know that many Administrator
    need to integrate with legacy system we're going to implement an email alert.
    Even if it's not the simplest approach (compare to a pagerduty or slack notification).

    You can check [this page](https://docs.kasten.io/latest/operating/monitoring.html) also for setting up alert with slack.
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
timelimit: 1800
---
# We need to configure a SMTP server

If you already have a smtp server and you know how to work with it you can skip this step.

For this lab we're going to use the smtp server of Yahoo.

Use or create a [yahoo email account](https://login.yahoo.com/).

In my case I have an account named choubaka@yahoo.com

![Yahoo account](../assets/yahoo-account.png)

Go to the [security page](https://login.yahoo.com/myaccount/security/)

![Yahoo security page](../assets/yahoo-account-security.png)

Find "Other way to sign in" and click on generate app password

![Other way to sign in](../assets/yahoo-account-security-other-way-to-signin.png)

Type grafana as the name of the app but it could be whatever you want.

![Other way to sign in](../assets/yahoo-account-security-other-way-to-signin-grafana.png)

Copy the password in my case it's `osildlyfxvrjvasg`

![Other way to sign in](../assets/yahoo-account-security-other-way-to-signin-copy-password.png)

This step is necessary because grafana has limited capacity to connect to modern smtp server.

# Configure grafana

Grafana is configured through the k10-grafana configmap.

In this configmap we defined the content of grafana.ini, we need to change it to add the smtp
section and restart the grafana pod.

Obtain the configmap to edit it :
```
kubectl get cm -n kasten-io k10-grafana -o yaml > k10-grafana-cm.yaml
```

At the end of the grafana.ini section add the smtp element

```
    [smtp]
    enabled=true
    host=smtp.mail.yahoo.com:465
    user=choubaka@yahoo.com
    password=osildlyfxvrjvasg
    from_address=choubaka@yahoo.com
    from_name=choubaka
```

Of course if you directly copy this values it won't work this password and account has been deleted.

Now replace the config map with the new values

```
kubectl replace -f k10-grafana-cm.yaml
```

And rollout the grafana deployment
```
kubectl -n kasten-io rollout restart deployment/k10-grafana
```

# Create an email channel and test it

Grafana define the notion of alert channel.
An alert channel let you choose which channel you want to map to wich alert.

Let's go to the grafana dashboard Usage & report > More charts

![go grafana](../assets/go-grafana-charts-usage-report.png)

![go grafana](../assets/go-grafana-charts.png)

Click on Alerting > Notification channels > Add Channel

![go grafana](../assets/alert-channels.png)

And choose Type: Email, name: email-channel, Adresses: <AN_EMAIL_YOU_CAN_CHECK> (in my case I used my email michael.courcy@gmail.com but of course use one that you can control)

And click test.

![email channel testing](../assets/alert-channels-test.png)

You must obtain a success

![email channel testing](../assets/alert-channels-test-success.png)

Check you mail box and verify that you get the mail from grafana

![email channel testing check email](../assets/alert-channels-test-email.png)

At this point you're all good to start working on alert rules.

Save the channel.


