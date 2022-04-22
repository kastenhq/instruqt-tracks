---
slug: only-one-challenge
id: huuyqsyi6zwx
type: challenge
title: Install Kasten in airgapped and multitenant mode with backup consistency
teaser: Let's combine your knowledge to create an airgapped + multitenant + application
  consistent configuration.
notes:
- type: text
  contents: Make sure you read all the notes to understand the challenge and how the
    final result will be evaluated.
- type: text
  contents: |-
    From the track:
    - Airgapped
    - Multitenant
    - Technical deep dive
    you must combine your skills to do an
    - Airgapped install (nfs + private docker registry)
    - With multitenancy (Keycloak as the oicd provider and configure OIDC Keycloak authentication for Kasten).
    - And backup a mongodb install (2 replicas + 1 arbiter) with a consistent blueprint.
- type: text
  contents: |-
    We create 2 machines :
    - nfs : hold the NFS share, the private registry and the keycloak server
    - k8s : hold the k8s cluster where you'll install Kasten

    You have to install all this components as you did in the previous tracks.
- type: text
  contents: |-
    The goal of this final track is to show that you have now enough understanding and practice to perform and troubleshoot this complex install.

    It is a combination exercice were all the steps that you should perform were already covered in the previous tracks, but you must
    prove that you can readapt in this new context and troubleshoot any issue you meet on the way.
- type: text
  contents: |-
    You also have to install a mongodb application and run a successful backup and export using a consistent blueprint.

    The final evaluation will check that
    - Kasten images are coming from a private registry
    - The location profile is based on NFS
    - Kasten use keycloak to authenticate users
    - One user is a Kasten admin, One user is a basic user with limited access to mongodb app
    - Backup of mongodb use a consistent blueprints

    You can review the previous tracks and the [Kasten documentation](https://docs.kasten.io).

    Good Luck !!
tabs:
- title: Terminal nfs
  type: terminal
  hostname: nfs
- title: Terminal k8s
  type: terminal
  hostname: k8svm
- title: Keycloak console
  type: website
  url: http://nfs.${_SANDBOX_ID}.instruqt.io:8080/
  new_window: true
- title: K10 Dashboard
  type: service
  hostname: k8svm
  path: /k10/#
  port: 32000
difficulty: advanced
timelimit: 7200
---

Useful links :

- [Kasten documentation](https://docs.kasten.io)
- [Aigapped install](https://play.instruqt.com/kasten/tracks/airgapped-install)
- [Multitenancy](https://play.instruqt.com/kasten/tracks/multitenancy-and-rbac)
- [Technical architecture deep dive](https://play.instruqt.com/kasten/tracks/technical-architecture-v2)

We also add some installation notes taken from the previous lab.
They are not necessarly complete and may need to be readapted to this new context.

They can also contains some errors that you may have to troubleshoot, use them carefully making sure you know what you're doing.

- [mongodb-with-consistent-blueprint-notes.md](https://github.com/michaelcourcy/airgapped-and-mutitenant-install/blob/master/mongodb-with-consistent-blueprint-notes.md)
- [airgapped-install-notes.md](https://github.com/michaelcourcy/airgapped-and-mutitenant-install/blob/master/airgapped-install-notes.md)
- [multitenancy-notes.md](https://github.com/michaelcourcy/airgapped-and-mutitenant-install/blob/master/multitenancy-notes.md)

You have 2 hours to successfully complete this installation.

Good Luck !!


