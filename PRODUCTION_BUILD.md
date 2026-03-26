# Production Build Guide (Flutter)

This project is now configured for production Android release builds with `key.properties` signing support.

## 1) One-time setup

### Android signing
1. Copy `android/key.properties.example` to `android/key.properties`.
2. Create your release keystore file (or use an existing one).
3. Update `android/key.properties` with real values.

### iOS signing
1. Open `ios/Runner.xcworkspace` in Xcode (on macOS).
2. Select the `Runner` target.
3. Set your Team and a unique Bundle Identifier.
4. Ensure Distribution certificate + App Store provisioning profile are configured.

## 2) PowerShell commands

Run from the project root:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

### Android (AAB for Play Store)
```powershell
flutter build appbundle --release
```
Output:
`build/app/outputs/bundle/release/app-release.aab`

### Android (APK for direct install/testing)
```powershell
flutter build apk --release
```
Output:
`build/app/outputs/flutter-apk/app-release.apk`

### iOS (App Store IPA)
Important: iOS builds require macOS + Xcode.  
Use PowerShell 7 (`pwsh`) on macOS:

```powershell
flutter clean
flutter pub get
cd ios
pod install --repo-update
cd ..
flutter build ipa --release
```
Output:
`build/ios/ipa/*.ipa`

### iOS (archive only, no codesign)
```powershell
flutter build ios --release --no-codesign
```

## 3) Versioning for store uploads

Update version in `pubspec.yaml`:

```yaml
version: 1.0.1+2
```

- `1.0.1` = user-visible version name
- `2` = build number/code (must increase for each store upload)
