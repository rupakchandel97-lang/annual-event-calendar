# Firebase Setup Guide

## Overview
This guide walks through setting up Firebase for the Family Calendar Android App.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Create a project** (or **Add project**)
3. Enter project name: `family-calendar`
4. Review Firebase terms and click **Continue**
5. (Optional) Enable Google Analytics
6. Click **Create project** and wait for initialization

## Step 2: Enable Firebase Services

### Authentication (Email/Password)
1. In Firebase Console, select your project
2. Go to **Build** → **Authentication**
3. Click **Get started**
4. Select **Email/Password**
5. Toggle **Enable** and click **Save**
6. (Optional) Configure authorized domains

### Firestore Database
1. Go to **Build** → **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development; change to production rules later)
4. Select your region (recommended: closest to you)
   - `us-central1` (default)
   - `europe-west1`
   - `asia-southeast1`
5. Click **Create database**

### Cloud Messaging (for notifications - optional for now)
1. Go to **Build** → **Messaging**
2. Click **Get started**
3. Information will be automatically available

### Storage (for event images - optional)
1. Go to **Build** → **Storage**
2. Click **Get started**
3. Choose **Start in test mode**
4. Select region and create

## Step 3: Get Firebase Credentials

### For Android

1. In Firebase Console, click **Project settings** (gear icon)
2. Select **General** tab
3. Under **Your apps**, click **Android** app or add a new one
4. Enter package name: `com.example.family_calendar`
5. Enter app nickname (optional): `Family Calendar`
6. Click **Register app**
7. Click **Download google-services.json**
8. Place file in: `android/app/google-services.json`

### For iOS

1. Click **Project settings** → **General** tab
2. Click **iOS** app or add a new one
3. Enter bundle ID: `com.example.family.calendar`
4. Enter app nickname (optional): `Family Calendar iOS`
5. Click **Register app**
6. Download `GoogleService-Info.plist`
7. Open `ios/Runner.xcworkspace` in Xcode
8. Right-click Runner → Add Files to Runner
9. Select `GoogleService-Info.plist`
10. Ensure it's added to Runner target

## Step 4: Update firebase_options.dart

Get your credentials from Firebase:

1. Click **Project settings** → **Service accounts**
2. Select **Flutter** from the dropdown
3. Copy the configuration shown

Update `lib/firebase_options.dart`:

```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    }
    throw UnsupportedError(...)
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy...',           // Copy from Firebase
    appId: '1:...:android:...',    // Copy from Firebase
    messagingSenderId: '...',       // Copy from Firebase
    projectId: 'family-calendar',   // Your project ID
    storageBucket: 'family-calendar.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy...',           // Copy from Firebase
    appId: '1:...:ios:...',        // Copy from Firebase
    messagingSenderId: '...',       // Copy from Firebase
    projectId: 'family-calendar',   // Your project ID
    storageBucket: 'family-calendar.appspot.com',
    iosBundleId: 'com.example.family.calendar',
  );
}
```

## Step 5: Configure Firestore Security Rules

1. In Firebase Console → **Firestore Database** → **Rules**
2. Replace the default rules with proper security rules:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users collection
    match /users/{userId} {
      allow read, update: if request.auth.uid == userId;
      allow create: if request.auth.uid != null;
      allow delete: if false;
    }

    // Families collection
    match /families/{familyId} {
      allow read: if request.auth.uid in resource.data.memberIds;
      allow update: if request.auth.uid == resource.data.adminId;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.adminId;

      // Nested: Family members
      match /members/{memberId} {
        allow read: if request.auth.uid in parent().data.memberIds;
      }
    }

    // Events collection
    match /events/{eventId} {
      allow read: if request.auth.uid != null;
      allow create: if request.auth.uid != null;
      allow update: if request.auth.uid == resource.data.createdBy;
      allow delete: if request.auth.uid == resource.data.createdBy || 
                       request.auth.uid == get(
                         /databases/$(database)/documents/families/$(resource.data.familyId)
                       ).data.adminId;
    }

    // Categories collection
    match /categories/{categoryId} {
      allow read: if request.auth.uid != null;
      allow create: if request.auth.uid != null;
      allow update: if request.auth.uid == get(
                         /databases/$(database)/documents/families/$(resource.data.familyId)
                       ).data.adminId;
      allow delete: if request.auth.uid == get(
                         /databases/$(database)/documents/families/$(resource.data.familyId)
                       ).data.adminId;
    }
  }
}
```

3. Click **Publish** to save

## Step 6: Create Firestore Indexes (Optional but Recommended)

For better query performance, create indexes:

1. Go to **Firestore Database** → **Indexes** tab
2. Manually add these composite indexes:

| Collection | Fields | Direction |
|----------|--------|-----------|
| events | familyId, date | Ascending, Ascending |
| categories | familyId | Ascending |
| users | email | Ascending |

Or let Firestore auto-create them when you run queries.

## Step 7: Test the Setup

1. Start your app: `flutter run`
2. Try to sign up
3. Create an event
4. Check Firestore console to see if data is created
5. Verify data appears in real-time in Firebase Console

## Step 8: (Optional) Enable Email Notifications

### Setting up Email Notifications

1. Go to **Build** → **Cloud Functions**
2. Click **Create function**
3. Name: `sendEventReminder`
4. Trigger: **Cloud Pub/Sub**
5. Create new topic: `event-reminders`
6. Deploy function with notification logic

## Troubleshooting Firebase Setup

### Authentication Issues

**Problem**: "Failed to initialize Firebase"
- **Solution**: 
  1. Verify `google-services.json` is in `android/app/`
  2. Check project ID matches Firebase console
  3. Ensure file is not corrupted

**Problem**: "Invalid API key"
- **Solution**:
  1. Check `firebase_options.dart` has correct API key
  2. Regenerate credentials from Firebase Console
  3. Try adding your app's package name to Firebase

### Firestore Issues

**Problem**: "Permission denied" when reading/writing
- **Solution**:
  1. Check Firestore security rules are deployed
  2. Verify user is authenticated
  3. Check user has appropriate permissions

**Problem**: "Document not found" errors
- **Solution**:
  1. Ensure Firestore database is created
  2. Check database location is correct
  3. Verify correct project ID is selected

### Build Issues

**Problem**: Android build fails with Firebase
- **Solution**:
  ```bash
  flutter clean
  cd android
  ./gradlew clean
  cd ..
  flutter pub get
  flutter run
  ```

**Problem**: iOS build fails with Firebase
- **Solution**:
  ```bash
  cd ios
  pod repo update
  pod install
  cd ..
  flutter run
  ```

## Production Deployment

Before deploying to production:

1. **Update Security Rules**
   - Replace test mode with production rules
   - Remove overly permissive rules
   - Test thoroughly

2. **Enable HTTPS**
   - All Firebase connections are HTTPS by default

3. **Set up Backups**
   - Enable automatic backups in Firestore
   - Test restore procedures

4. **Monitor Usage**
   - Set up Firebase Analytics
   - Monitor Firestore read/write operations
   - Set up billing alerts

5. **Enable Only Needed Services**
   - Disable unused Firebase services
   - Reduces exposure and costs

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Console](https://console.firebase.google.com)
