# login_signup

A Flutter project.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and on your `PATH`
- For **iOS**: a Mac with Xcode installed (App Store), plus [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) (`sudo gem install cocoapods`)
- For **Android**: [Android Studio](https://developer.android.com/studio) with the Android SDK, and a device or emulator

Run `flutter doctor` to check that everything is set up correctly before continuing.

## Setup

1. Clone the repository and open a terminal in the project root.
2. Install dependencies:
   ```
   flutter pub get
   ```

## Running on Android

1. Start an Android emulator (via Android Studio's Device Manager) or plug in a physical device with USB debugging enabled.
2. Check the device is detected:
   ```
   flutter devices
   ```
3. Run the app:
   ```
   flutter run
   ```
   If you have multiple devices connected, specify one:
   ```
   flutter run -d <device-id>
   ```

## Running on iOS

1. Install CocoaPods dependencies:
   ```
   cd ios
   pod install
   cd ..
   ```
2. Start an iOS Simulator (via Xcode > Open Developer Tool > Simulator) or connect a physical iPhone (requires an Apple Developer account signed into Xcode for on-device runs).
3. Check the device is detected:
   ```
   flutter devices
   ```
4. Run the app:
   ```
   flutter run
   ```
   If you have multiple devices connected, specify one:
   ```
   flutter run -d <device-id>
   ```

## Troubleshooting

- Run `flutter doctor -v` to diagnose missing tooling.
- If iOS build errors mention pods being out of date, run `pod repo update` inside the `ios` folder, then `pod install` again.
- If a connected device isn't listed, restart it or re-run `flutter devices`.

## Learn more

- [Flutter documentation](https://docs.flutter.dev/)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter cookbook](https://docs.flutter.dev/cookbook)
