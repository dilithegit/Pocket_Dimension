---
name: release-workflow
description: Mandates pre-release documentation alignment, version synchronization, release signing security, and mandatory secrets build flags for Pocket Dimension releases.
---

# Release Workflow Skill

## Objective
Never publish a release without the README reflecting current reality first, and never compile release APKs without mandatory secrets flags and release signing.

## Rules of Engagement
- Before any version tag or GitHub release: README must be updated to match the current architecture, feature set, and skills list — no exceptions.
- Version number in `pubspec.yaml` and `README.md` must always match.
- **Mandatory Secrets Flag**: All build commands (`flutter build apk`, `flutter run`) MUST explicitly include `--dart-define-from-file=secrets.json` (and `--android-skip-build-dependency-validation` when compiling APKs).
- Release APKs must be signed with the release keystore (`android/key.properties`), never the debug key.
- Keystore and `key.properties` are never committed — verified via `git status` before every release.
- Release notes must summarize actual changes since the last tag.
