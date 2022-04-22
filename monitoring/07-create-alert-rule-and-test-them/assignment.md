---
slug: create-alert-rule-and-test-them
id: yvzrfkmwxvib
type: challenge
title: Create a dashboard with your own alert rules
teaser: We're going to create your own grafana dashboard where you'll also set up
  your alert rules.
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
# Create a new dashboard

Call it "Alert dashboard"

![Create a new dashboard](../assets/alert-create-dashboard.png)

Use the metrics browser to create `catalog_actions_count{status="failed"}`

![metrics browser](../assets/alert-panel-create-request.png)

Rename 'A' to 'failed backup'

Choose old graph

![Choose Old graph](../assets/alert-panel-choose-old-graph.png)

Go on the alert tab and create an alert based on `percent_diff > 0`

![Alert rule](../assets/alertrule-rule.png)

```
percent_diff = (newest - oldest) / math.Abs(oldest) * 100
```

percent_diff
- (1) will trigger an alert if the number of backup_failed just increase (percent_diff > 0).
- (2) Once the alert is on it stays on pending state for 5 minute, after this time it transitions on alerting. It's only when transitioned on alerting state that the alert is sent to the notification channel.
- (3) newest = now and oldest = now - 1h

# Define the channel as email-channel and template your message

![Alert rule template](../assets/alertrule-template.png)

Copy and paste this template message
```
cat <<EOF
You've got a failure on \${policy}  on your cluster !! Quickly check kasten dashboard to understand what's going on :

https://k8svm-32000-${INSTRUQT_PARTICIPANT_ID}.env.play.instruqt.com/k10/
EOF
```

Any criteria from the metrics can be used, in this case we use ${policy} to capture the name
of the policy that fails.

To find out the list of available criteria click on Test

![Test alert](../assets/alertrule-test.png)

Select the notification channel as "email-channel" that we created in the previous steps.

Save again to persist the alert rule.

# Test the alert rule

Now that the rule is created it's time to test it

Failed again the policy as you did the last time.

Once the policy is failed check the alertrule history

![Alert rule history](../assets/alertrule-history.png)

Check your mail within 10 minutes you must have received the alert.

Notice that `${policy}` has been replaced by the name of the policy "mongodb-backup".

![Alert rule email](../assets/alertrule-email.png)

Congratulation your alerting system is up and running, this is a very important component when
you manage a lot of clusters and a lot of policies on production.


