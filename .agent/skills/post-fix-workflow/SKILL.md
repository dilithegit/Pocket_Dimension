---
name: post-fix-workflow
description: Use after every code change/bug fix made to Pocket Dimension, without needing to be re-asked. Covers the required sequence — test, build, install to the physical test device, then commit and push to GitHub. Trigger on any completed fix, feature change, or refactor in this project.
---

# Pocket Dimension — Post-Fix Workflow

Every change to this project follows the same sequence before it's considered done.
Don't skip steps or reorder them, and don't ask the user to manually run this — do
it as part of finishing the fix.

## The sequence

1. **Test.** Run `flutter analyze` and `flutter test`. Show the real output, not a
   summary. If either fails, stop here — do not proceed to install or commit.
   Report exactly what failed and fix it before moving on.

2. **Build & install.** Once tests pass, confirm the physical device is connected
   (`flutter devices` or `adb devices`) — the target device is the Samsung SM A057F
   over USB. Run `flutter run` (or `flutter install` if a build already exists) to
   get the fix onto that device. If the device isn't connected, say so clearly and
   skip this step rather than silently failing or waiting indefinitely — commit and
   push can still proceed independently.

3. **Commit.** Write a commit message describing what the fix actually does (not
   "fix bug" — name the symptom and the cause, e.g. "Fix chat back button exiting
   app: add explicit back-stack + PopScope to state router"). Use judgment on
   granularity: a tightly-related set of changes (e.g. a bug fix plus its test)
   can be one commit; unrelated fixes made in the same session should be separate
   commits so history stays readable and revertable. Never bundle a passing fix
   together with unrelated in-progress/broken work in the same commit.

4. **Push.** Push to the existing GitHub remote. Do not push if step 1 failed —
   broken code shouldn't land on the remote even temporarily. If a push is
   rejected (e.g. remote has commits not present locally), stop and report that
   rather than force-pushing.

## Reporting back

After completing the sequence for a fix, report concisely: what changed, whether
tests passed, whether it installed to the device, and the commit hash(es) pushed.
Skip any step and say so explicitly rather than letting it pass silently (e.g. "no
device connected, skipped install, committed and pushed only").

## Exceptions

- Documentation-only changes (this skill file, README, comments) don't need a
  device install, but should still run through analyze/test if any code was
  touched, and should still be committed/pushed.
- If a fix is exploratory/being debugged interactively (e.g. temporary debug
  logging added to diagnose an issue), don't push that to GitHub until the debug
  code is either kept intentionally or removed — flag this to the user rather
  than assuming.
