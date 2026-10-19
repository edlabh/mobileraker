# Mobileraker Lite on iOS (free Apple ID)

This guide shows how to build and install the app on your iPhone **without the paid
Apple Developer account** (US$ 99/year), using only a free Apple ID. Personal,
non-commercial use only (Mobileraker License v2). Do not distribute the compiled app.

Este guia mostra como compilar e instalar o app no iPhone **sem a conta paga da Apple**,
usando só um Apple ID gratuito. Uso pessoal e não comercial. Não distribua o app compilado.

## What works and what does not

Works: printer control, dashboard, camera, files, graphs, Spoolman, G-code preview,
print queue, themes.

Does not work with a free Apple ID:

- Push notifications of the Mobileraker Companion (they need APNs, paid account only).
- Widgets and Live Activities (they need App Groups).
- Purchases, App Check and Remote Config (Firebase runs with development values, see below).

## Limits of the free account

- The app **expires after 7 days** and must be reinstalled. The app data is kept.
- At most **3 apps** installed this way.
- At most **10 new App IDs per week**: pick your Bundle ID once and keep it.

## Requirements

- A Mac with Xcode (new iOS versions need a new Xcode).
- Flutter matching `pubspec.yaml` (`flutter: >=3.32.0`) and CocoaPods.
- An iPhone with a cable and **Developer Mode** on
  (Settings > Privacy & Security > Developer Mode, the phone restarts).

## 1. Get the code

```
git clone https://github.com/edlabh/mobileraker
cd mobileraker
flutter pub get
(cd common && flutter pub get && dart run build_runner build --delete-conflicting-outputs)
dart run build_runner build --delete-conflicting-outputs
```

`mobileraker_pro` is already inside the repository, there is nothing else to clone.

## 2. Firebase (development values)

The app initializes Firebase on start. Two files are git-ignored and you must create them.
Without them the build fails or the app closes right after opening.

**Important:** the API key must have **exactly 39 characters** (format `AIza...`).
A short key such as `local-dev-key` makes the app close on launch with
`FirebaseInstallations ... API Key length must be 39 characters`.

`mobileraker_pro/lib/firebase_options.dart` (fake values):

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported in this local build.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIza' 'SyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', // 39 characters in total
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'mobileraker-local-dev',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIza' 'SyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', // 39 characters in total
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'mobileraker-local-dev',
    iosBundleId: 'com.yourname.mobileraker', // same as MOBILERAKER_BUNDLE_ID below
  );
}
```

`ios/Runner/GoogleService-Info.plist` with the same fake values (`API_KEY`, `GCM_SENDER_ID`,
`BUNDLE_ID`, `PROJECT_ID`, `GOOGLE_APP_ID`).

With these values the app opens, but Remote Config, App Check and purchases do not really
work. For real Firebase, create a free project and run `flutterfire configure` with your
Bundle ID. **Never commit these files.**

## 3. Signing with a free Apple ID

1. Copy the example and fill in your values:

   ```
   cp ios/Flutter/Local.xcconfig.example ios/Flutter/Local.xcconfig
   ```

   | Setting | Value |
   |---|---|
   | `MOBILERAKER_BUNDLE_ID` | A unique id of yours, e.g. `com.yourname.mobileraker`. The upstream id belongs to its author. |
   | `MOBILERAKER_TEAM_ID` | Your Personal Team ID (10 characters, shown in Xcode > Signing & Capabilities after you add your Apple ID). |
   | `MOBILERAKER_ENTITLEMENTS` | `Runner/RunnerFree.entitlements` (empty, a free Apple ID cannot use Push, App Groups, iCloud...). |
   | `MOBILERAKER_FREE_SIGNING` | `YES`: `pod install` removes the Live Activity and Notification Service extensions and the Crashlytics symbol upload phase from the Runner target. |

   `Local.xcconfig` is git-ignored. The defaults in `Signing.xcconfig` are the upstream
   values, so the regular paid build is unchanged when you do not create `Local.xcconfig`.

2. Add your Apple ID in Xcode: Xcode > Settings > Accounts > **+**.
3. Apply the settings:

   ```
   cd ios && pod install
   ```

   Run it again every time you change `Local.xcconfig`.

4. Do not accept Xcode's "Update to recommended settings".

**Undo the free mode:** delete `Local.xcconfig` (or set `MOBILERAKER_FREE_SIGNING = NO`),
run `git checkout ios/Runner.xcodeproj` and `pod install`.

## 4. Build and install

```
flutter build ios --release
xcrun devicectl list devices
xcrun devicectl device install app --device <DEVICE_ID> build/ios/iphoneos/Runner.app
```

The first time, the Mac asks for your keychain password for `codesign`. Then, on the
iPhone: Settings > General > **VPN & Device Management** > tap your Apple ID > **Trust**.

For `flutter run --debug` keep the iPhone connected: a debug app does not open by itself
from the home screen.

## 5. Renew every 7 days

Connect the iPhone and run step 4 again. The app data is kept.

Renewing without a cable:

- **AltStore**: AltServer on the Mac, same Wi-Fi network. _Not verified by the author of this guide._
- **SideStore**: renews on the iPhone, after an initial setup that needs a computer.
  _Not verified on iOS 27._

## 6. Install without a Mac

Building needs a Mac with Xcode, installing an already built `.ipa` does not.
An unsigned `.ipa` can be signed on your own with your Apple ID by
Sideloadly, AltStore or SideStore. _Not verified by the author of this guide._

## 7. Known problems

| Symptom | Cause | Fix |
|---|---|---|
| The app opens and closes right away, with `UIScene lifecycle is required on iOS 27 and later` | Missing UIScene lifecycle | Fixed in this branch (`AppDelegate.swift`, `Info.plist`) |
| The app closes on launch with `API Key length must be 39 characters` | Fake API key too short | Use a 39 character key (section 2) |
| `Build input file cannot be found: GoogleService-Info.plist` | Missing file | Create it (section 2) |
| `Ambiguous use of init(stringRepresentation:)` in the RevenueCat pod | RevenueCat 5.67 does not build with the Swift of Xcode 27 | Fixed by `purchases_flutter ^10.16.0` (run `pod update PurchasesHybridCommon RevenueCat` if CocoaPods reports a version conflict) |
| `CocoaPods's specs repository is too out-of-date` | Old local spec cache | `pod repo update` |
| Yellow warning "no devices from which to generate a provisioning profile" | No iPhone connected | Connect it, trust the Mac and press "Try Again" |
| The app stopped opening after some days | 7 day limit of the free Apple ID | Reinstall (section 5) |
