---
slug: restorepoints
id: o3fmzefgrhcy
type: quiz
title: Restorepoints, local vs exported
teaser: Check you understand the difference between local and exported restorepoints
answers:
- Local restorepoint and exported restorepoint are always coming by pair
- 'You may have a local restorepoint without an exported restorepoint '
- 'You may have an exported restorepoint without a local restorepoint '
- If you delete an exported restorepoint you also delete the local restorepoint
- If you delete an exported restorepoint you delete data in the object storage location
  but also the local volumesnapshot
- If you delete a local restorepoint you delete local volumesnapshot and the captured
  spec in the catalog
- Restore from a local restorepoint means recreate data from a local snaphot
- Restore from a local restorepoint means recreate data from a local snaphot and if
  missing restore from the object storage location
- Restore from an exported restorepoint means checking first for local snapshot and
  if not available use the object storage location
- You can't create an exported restorepoint without creating first a local restorepoint
- A migration always happen by importing in another cluster an exported restore point
- The namespace manisfest in an exported restore point are only on the object storage
  location but not in the catalog
- The namespace manisfest in an exported restore point are not on the object storage
  location but only in the catalog
- The namespace manisfest in an exported restore point are both on the object storage
  location and in the catalog
solution:
- 1
- 2
- 5
- 6
- 9
- 10
- 13
difficulty: basic
timelimit: 500
---
In Kasten we speak about restorepoint, local restorepoint and exported restorepoint. Let's see if you understand the differences and when they are used.

If you have difficulties to answer close and switch to challenge where you can try backup, export and restore. Then comeback to this one and provide
good answers.