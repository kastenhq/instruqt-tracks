---
slug: datamover-kopia-deduplication
id: b7ewbnpqr1kh
type: quiz
title: The datamover kopia, deduplication
teaser: Check you understand the deduplication capacity of Kopia
notes:
- type: text
  contents: Kasten has been designed for hybrid cloud since the beginning. Knowing
    that migration will be done from a cloud provider to to on premise and vice-versa.
- type: text
  contents: |-
    Hence it was important to make "portable backup"

    - Backup that could be exported to a cloud location such as AWS S3, S3 compatible, Azure blob container, Google storage bucket ...
    - Backup that will be encrypted at rest (before being sent on the network) with keys that Kasten manage
    - Backup that could be imported in a different storage solution, from AWS to Azure for instance.
- type: text
  contents: |-
    For this reason Kopia has been chosen as the default Kasten's datamover.

    - Kopia is a filesystem backup tool
    - Kopia encrypt at rest before sending the data to the cloud repository
    - All Kopia snapshots are incremental
    - Kopia is a Content-Addressable Object Storage (CAOS), which avoid deduplication.

    Let's see how Kopia manage it's backup, and why we never speak about full or differential backup.
- type: text
  contents: |-
    We're reprensenting here a Kopia repository on "tuesday".

    The backup started on Monday, f1 and f2 were captured

    On tuesday nothing have changed, hence the manifest of tuesday just  point to the existing files.

    Only hash information are exchanged to controls the files but on tuesday no files is sent to the network.

    ![--](../assets/backkup-on-tuesday.png)
- type: text
  contents: |-
    On wednesday we do Two things

    - We add a new file f3 on the pvc
    - We delete the first backup ( the monday one).

    We actually delete the backup manifest but not the content of the files, because other backups references those files

    ![--](../assets/backkup-on-wednesday.png)
- type: text
  contents: |-
    On thursday we delete f1 in the PVC
    But we cant delete the content of f1 because the backup of tueday and wednesday are still pointing to f1.

    Only when those 2 backup manifest will be removed (tueday and wednesday) then f1 could be garbage collected.

    ![--](../assets/backkup-on-thursday.png)
- type: text
  contents: |-
    To summarize :
    - There is one full backup which is the initial one.
    - After that Kopia only capture and export the change to the repository
    - Files content are removed only when no backup manifest point to them
answers:
- Kopia use hash to identify similar file even if they are under different name or
  different folder
- Kopia use Content Block tracking
- Kopia use File System tracking
- 'Kopia use deduplication within a backup but not  between two backups '
- Kopia always do incremental backup
- Kopia always do full backup
- Kopia always do incremental backup except when it promotes a backup from daily to
  weekly
- Kopia always keep at least one copy of the file that has existed in the volume
- Kopia garbage collect files that are not referenced anymore in any backup
solution:
- 0
- 2
- 4
- 8
difficulty: basic
timelimit: 600
---
Which of the sentences about Kopia are true