# Contributing

Thanks for wanting to help. Bug reports, ideas and PRs are all welcome.

## Before you start

- For a bug, open an issue with the bug report form. Steps to reproduce help me the most.
- For a new feature or a big change, open an issue first so we can talk about it. I don't want you to spend hours on a PR I can't merge.
- Small fixes (typos, docs, an obvious bug) can go straight to a PR.
- Security problems don't go in issues, see [SECURITY.md](SECURITY.md).

## Setup

You need Flutter 3.44 or newer.

```
git clone https://github.com/AhmedAbdoElhawary/image_picker_plus.git
cd image_picker_plus
flutter pub get
```

To try your change, run the example app:

```
cd example
flutter run
```

## Making a change

1. Fork the repo and make a branch from `main`.
2. Keep the PR on one thing. Two fixes are easier to review as two PRs.
3. Add or update tests for what you changed.
4. If users will notice the change, add a line under the top section of `CHANGELOG.md`.
5. Run the checks below, then open the PR.

## Checks

These are the same checks the CI runs on every PR:

```
dart format --output=none --set-exit-if-changed lib test example/lib example/integration_test example/test_driver
flutter analyze --fatal-infos
flutter test --coverage
flutter pub publish --dry-run
```

The CI fails when line coverage is under 80%. The `services/*_impl.dart` and `platform/*` files are left out, because only a real device can run them.

The CI also builds the example for Android, iOS, web, macOS, Windows and Linux, so a change that breaks one platform shows up there.

## Speed

If your change touches the gallery, check the scroll speed on a real device in profile mode:

```
cd example
flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/gallery_scroll_test.dart
```

## Releasing

This part is for me, but here it is so it's not a secret:

1. Bump `version:` in `pubspec.yaml` and add a `## x.y.z` section at the top of `CHANGELOG.md`.
2. Merge to `main`.
3. Push the tag: `git tag vx.y.z && git push origin vx.y.z`.

The release workflow checks the tag against `pubspec.yaml` and `CHANGELOG.md`, publishes to pub.dev and creates the GitHub release with that CHANGELOG section.

## Code of conduct

Be kind. The full version is in [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
