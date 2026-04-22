---
description: How to run the Flutter App with flavors
---

# Running the App with Flavors

The Flutter app is configured to use two product flavors: `internal` and `external`. 
Because flavors are defined in `android/app/build.gradle.kts`, you must specify the flavor explicitly when running or building the app, otherwise the build will fail.

## Running the App

To run the app on an active emulator or connected device:

### Internal Flavor
```bash
flutter run --flavor internal -t lib/main.dart
```

### External Flavor (Default)
```bash
flutter run --flavor external -t lib/main.dart
```

---

## Building the App

To build APK files:

### Build Internal APK
```bash
flutter build apk --flavor internal -t lib/main.dart
```

### Build External APK
```bash
flutter build apk --flavor external -t lib/main.dart
```

## Troubleshooting
If you encounter `Unresolved reference: filePermissions` building on Android, ensure that your Gradle setup (in `android/gradle/wrapper/gradle-wrapper.properties` and `android/settings.gradle.kts`) is up to date with the installed Flutter framework version.
