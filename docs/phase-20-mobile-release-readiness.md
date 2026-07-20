# Phase 20 - Mobile release readiness

Habitar is mobile-first. Web remains a preview/build target, not the primary launch surface.

## Android identity

- App label: Habitar
- Application ID: com.habitar.app
- Android namespace: com.habitar.app
- Internet permission: enabled for Supabase/Auth/API access

## Android signing

Release signing is configured to read `apps/mobile/android/key.properties`.
That file and the keystore are ignored by Git.

Create them locally before Play Store release:

1. Copy `apps/mobile/android/key.properties.example` to `apps/mobile/android/key.properties`.
2. Generate `apps/mobile/android/app/upload-keystore.jks`.
3. Replace the placeholder passwords in `key.properties`.
4. Build with `flutter build appbundle`.

Until `key.properties` exists, release builds fall back to debug signing so development builds can still run.

## Local Android toolchain note

On Windows, Gradle needs `JAVA_HOME` set before Android builds:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
```

Validated locally:

- `flutter analyze apps/mobile`
- `flutter build apk --debug`
- `./gradlew.bat bundleRelease --stacktrace --no-daemon`

Generated artifacts:

- `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- `apps/mobile/build/app/outputs/bundle/release/app-release.aab`

The current `.aab` is for technical validation only until the release keystore is created.

## Store readiness still pending

- Final app icon and adaptive Android icon.
- Splash screen polish.
- Play Store listing copy.
- Privacy policy and terms URLs.
- Production Supabase project and security verification.
- Android release keystore creation.
- iOS bundle ID, signing, Apple Developer setup, and Xcode validation.
