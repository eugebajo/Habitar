# Phase 21 - Android Play Store readiness

Habitar will not launch as a web-first product. Web remains a preview target.
The launch path is Android first, then iOS.

## Current Android release status

- Package/application ID: `com.habitar.app`
- App label: `Habitar`
- Compile SDK: 36
- Target SDK: 36
- Release signing: configured through private `apps/mobile/android/key.properties`
- Upload keystore: pending local creation
- Debug APK: validated in Phase 20
- Technical release AAB: validated in Phase 20

## Why API 36 now

Google Play requires new apps and app updates to target Android 16 / API 36
or higher starting August 31, 2026. Habitar now targets API 36 so the release
track is not built on a target SDK that will age out immediately.

## One-time machine setup

Android Studio still needs command-line tools and license acceptance.

1. Open Android Studio.
2. Go to `More Actions > SDK Manager`.
3. Open `SDK Tools`.
4. Enable:
   - Android SDK Command-line Tools latest
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - NDK
   - CMake
5. Apply changes.
6. In PowerShell:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
C:\Users\eugen\flutter\bin\flutter.bat doctor --android-licenses
C:\Users\eugen\flutter\bin\flutter.bat doctor -v
```

## Create the private upload key

Run this from the repo root:

```powershell
.\scripts\android_create_upload_keystore.ps1
```

Then edit:

```text
apps/mobile/android/key.properties
```

Replace all `change-me` values with the passwords entered during key creation.
Never commit `key.properties` or `upload-keystore.jks`.

## Build the signed Play bundle

After the private key is configured:

```powershell
.\scripts\android_build_release.ps1
```

The signed bundle should be generated at:

```text
apps/mobile/build/app/outputs/bundle/release/app-release.aab
```

## Play Console checklist

- Create app in Google Play Console.
- App name: Habitar.
- Default language: Spanish.
- App or game: App.
- Free or paid: decide before production.
- Upload signed `.aab` to Internal testing first.
- Complete App content:
  - Privacy policy URL.
  - Data safety form.
  - Content rating questionnaire.
  - Target audience and families declaration.
  - Ads declaration.
  - App access instructions if login is required.
- Complete Store listing:
  - Short description.
  - Full description.
  - App icon.
  - Feature graphic.
  - Phone screenshots.
  - Support email.
  - Website/domain.

## Policy-sensitive notes for Habitar

Habitar handles family, child/adolescent profile, routine, habit, wellbeing,
and authentication data. This requires careful privacy wording and accurate
Data safety declarations.

Avoid requesting sensitive Android permissions unless the feature truly needs
them. Current Android manifest only requests Internet, which is appropriate for
Supabase/Auth/API access.

## Still pending before production

- Final icon/adaptive icon.
- Final splash screen.
- Production Supabase security review.
- Privacy policy and terms hosted on Habitar-owned domain.
- Support email for Habitar.
- Store screenshots.
- Internal testing group.
- iOS bundle/signing setup.

## Official references checked

- Google Play target API requirement:
  `https://developer.android.com/google/play/requirements/target-sdk`
- Flutter Android release/signing guide:
  `https://docs.flutter.dev/deployment/android`
- Google Play Data safety form guidance:
  `https://support.google.com/googleplay/android-developer/answer/10787469`
