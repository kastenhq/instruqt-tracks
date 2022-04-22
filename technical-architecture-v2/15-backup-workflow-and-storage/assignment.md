---
slug: backup-workflow-and-storage
id: 9utlydurlq1j
type: quiz
title: Backup and export Workflow with CSI or direct intregration
teaser: Check that you understand how storage artifact are created when backup and
  export happens with CSI  or direct intregration
answers:
- Clone PVC in Kasten namespace  are created from PVC in application namespace-> data
  mover pod mount the clone PVC to export them to the object storage location -> Clone
  PVC in Kasten namespace are kept for local restore point
- Snapshot are created from the PVC -> Clone PVC are created from those snapshot in
  Kasten ns -> data mover move them to the object storage location -> Clone PVC in
  Kasten Namespace are deleted after the export action
- Snapshot are created from the PVC and kept for local restorepoint
- Snapshot are created from the PVC and kept for local restorepoint, deletion of the
  local restorepoint does not delete the snapshot
- Snapshot are created from the PVC and kept for local restorepoint, deletion of the
  local restorepoint does delete the snapshot
- Deletion of the exported restore point automatically delete the local restorepoint
  and the snapshot attached
- Manifests captured in a namespace (deployment, secrets, config map ...) are included
  in the snapshots created by the backup action
- Manifests captured in a namespace (deployment, secrets, config map ...) are saved
  only on the object storage location when an export action happen
- 'Manifests captured in a namespace (deployment, secrets, config map ...) are saved
  in the catalog '
- Manifests captured in a namespace (deployment, secrets, config map ...) are saved
  both in the catalog but also in the object storage location if an export action
  happens
solution:
- 1
- 2
- 4
- 8
- 9
difficulty: basic
timelimit: 400
---
When a CSI or direct integration backup followed by an export happens what is the correct workflow (multiple answers).

If you have difficulties to answer close and switch to challenge where you can try backup, export and restore. Then comeback to this one and provide
good answers.