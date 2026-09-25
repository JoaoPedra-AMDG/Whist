# Whist scorekeeper

A minimal, offline Flutter scorekeeper for a physical Whist game. The app records calls and tricks, enforces the final caller rule, calculates scores, and allows completed rounds to be corrected.

## Run

Install Flutter 3.29 or newer, then from this folder:

```sh
flutter pub get
flutter run
```

For checks:

```sh
flutter analyze
flutter test
```

Android and iOS project files are included. iOS builds require macOS and Xcode.

## Structure

- `lib/models`: game and round data, with JSON serialization.
- `lib/logic`: round rules, scoring, and in-memory controller.
- `lib/services`: local storage bridge.
- `lib/screens`: setup, play, corrections, score sheet, results, and rules.
- `test`: rules, scoring, correction, and serialization tests.

The game history is the source of truth. Totals are recalculated from completed rounds whenever shown. Draft calls and results are saved after each selection. Android uses SharedPreferences and iOS uses UserDefaults through a small method channel, so no account, network access, or third-party package is required at runtime.

## Rules assumption

Calls are entered in the fixed player order chosen during setup. The first caller does not rotate between rounds because no rotation rule was specified. Trump selection and card play are handled by players with the physical deck; the app tracks only final trick counts.
