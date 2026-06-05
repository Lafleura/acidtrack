# acidtrack

Flutter app scaffolded for Android-first development.

## Prerequisites (WSL)

- Flutter (stable) installed in WSL (example: `/home/lafleuralan/dev/flutter`)
- Android Studio installed on Windows with Android SDK + emulator images
- Java 17 available in WSL

## Setup

1. Verify Flutter:
   ```bash
   flutter --version
   flutter doctor -v
   ```
2. Point Flutter to your Android SDK (adjust path if different):
   ```bash
   flutter config --android-sdk /mnt/c/Users/<you>/AppData/Local/Android/Sdk
   ```
3. Accept Android licenses:
   ```bash
   flutter doctor --android-licenses
   ```

## Project Commands

From this repository root:

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```

## Run on Android Emulator

1. Start an Android emulator from Android Studio on Windows.
2. In WSL, verify device visibility:
   ```bash
   flutter devices
   ```
3. Run app:
   ```bash
   flutter run -d eumlator-5554 --release
   ```

If no emulator is listed, confirm Android SDK path and that `adb` from the same SDK is accessible.
