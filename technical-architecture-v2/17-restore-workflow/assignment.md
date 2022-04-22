---
slug: restore-workflow
id: 0tljlb15asjx
type: quiz
title: Restore workflow
teaser: Check you understand what happens when you restore from a local or an exported
  restorepoint.
answers:
- 'When restoring in an existing namespace all restored PVC are first deleted if they
  already exist '
- When restoring in an existing namespace all restored PVC are kept if they already
  exist, only the change are applied
- If secret "my-secret" already exist it won't be replaced by the one in the restorepoint
  during restore even if it's content is different
- If secret "my-secret" already exist it will be replaced by the one in the restorepoint
  during restore even if it's content is different
- 'During restoration first workloads are scaled down then PVC deleted '
- 'During restoration workloads are not scaled down if they are running only the PVC
  is replaced '
- Restoring from a local restorepoint is always quicker that restoring from an exported
  restorepoint
- 'Once restore is successful only local restorepoint is deleted '
- 'Once restore is successful only exported restorepoint is deleted '
- 'Once restore is successful both local and exported restorepoint is deleted '
solution:
- 0
- 2
- 4
difficulty: basic
timelimit: 600
---
When restoring many things happen behind the scene, things could be different if you restore from a local or an exported restorepoint.

If you have difficulties to answer close and switch to challenge where you can try backup, export and restore. Then comeback to this one and provide
good answers.