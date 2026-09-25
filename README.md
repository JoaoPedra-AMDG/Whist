# Whist scorekeeper

A minimal, offline Flutter scorekeeper for a physical Whist game. The app records calls and tricks, enforces the final caller rule, calculates scores, and allows completed rounds to be corrected.

## Play on a phone

Open **[Whist Scorekeeper](https://joaopedra-amdg.github.io/Whist/)** in your browser. On Android, use Chrome's **Install app** menu item. On iPhone, open the link in Safari and choose **Share → Add to Home Screen**.

Games are saved on each device separately; the web app does not sync scores between phones.

## Change the app icon

Replace `assets/branding/whist-cards.png` with a new PNG, then run `./tool/generate_icons.ps1` in PowerShell. The script creates the web, Android, iOS, macOS, and Windows icons from that image. Commit and push the updated files to publish the web icon. If an existing home screen shortcut still shows the old icon, remove it and add it again after the site updates.

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

Android, iOS, Windows, macOS, Linux, and web project files are included. iOS builds require macOS and Xcode.

## Structure

- `lib/models`: game and round data, with JSON serialization.
- `lib/logic`: round rules, scoring, and in-memory controller.
- `lib/services`: local storage bridge.
- `lib/screens`: setup, play, corrections, score sheet, results, and rules.
- `test`: rules, scoring, correction, and serialization tests.

The game history is the source of truth. Totals are recalculated from completed rounds whenever shown. Draft calls and results are saved after each selection. Android uses SharedPreferences and iOS uses UserDefaults; desktop builds save a local JSON file and web uses browser storage. The only runtime dependency is the Dart `web` package for browser storage. No account or network access is required. A failed save leaves the last confirmed round intact and shows details and retry steps.

## Rules assumption

Calls are entered in the fixed player order chosen during setup. The first caller does not rotate between rounds because no rotation rule was specified. Trump selection and card play are handled by players with the physical deck; the app tracks only final trick counts.
