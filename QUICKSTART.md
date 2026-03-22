# Quick Start Guide

Get the Family Calendar app up and running in 10 minutes!

## 📋 Prerequisites

Before starting, ensure you have:
- Flutter 3.0+ installed ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart 3.0+ (comes with Flutter)
- A Firebase account (free tier is sufficient)
- A code editor (VS Code recommended)

## 🚀 5-Minute Setup

### Step 1: Navigate & Install
```bash
# Navigate to the project folder
cd "C:\Work\Projects\Annual Event Calendar"

# Install dependencies
flutter pub get
```

### Step 2: Setup Firebase (2 minutes)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named "family-calendar"
3. Add Android app → Package name: `com.example.family_calendar`
4. Download `google-services.json` → Place in `android/app/`
5. Enable Firestore Database (Start in test mode)
6. Enable Authentication (Email/Password)

### Step 3: Configure Firebase Credentials (1 minute)
1. In Firebase Console → Project Settings → General
2. Copy your credentials
3. Update `lib/firebase_options.dart` with your credentials

### Step 4: Run the App (2 minutes)
```bash
# Connect an Android device/emulator
flutter run

# Or specify device:
flutter run -d <device_id>
```

## ✅ Verify Installation

1. **App Launches** ✓
   - You should see the Login screen

2. **Create Account** ✓
   - Click "Sign Up"
   - Enter: name, email, password
   - Click "Create Account"

3. **Add Event** ✓
   - Click "+" button
   - Fill event details
   - Click "Save Event"

4. **View Calendar** ✓
   - Click "Calendar" tab
   - See your event displayed

If all checks pass, you're ready! 🎉

## 📁 Project Structure Quick Reference

```
lib/
├── main.dart                    # App entry
├── models/                      # Data models
├── providers/                   # State logic
├── screens/                     # UI screens
└── routes/                      # Navigation
```

## 🔑 Key Features to Try

### 1. Authentication
- Sign up → Sign in → View profile

### 2. Calendar
- Click "Open Calendar" on home
- Navigate between months
- Tap a date to see events

### 3. Events
- Click "+" to create event
- Fill in details
- View in calendar

### 4. Family
- Go to Settings → Family Members
- Invite members (email)
- Share calendar

### 5. Categories
- Go to Settings → Categories
- Add/delete categories
- Assign colors

## 📞 Common Issues & Solutions

### Issue: "google-services.json not found"
**Solution**: 
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean` and try again

### Issue: "Firebase initialization failed"
**Solution**:
- Check credentials in `firebase_options.dart`
- Verify Firebase project is created
- Ensure Firestore database is enabled

### Issue: "Permission denied" errors
**Solution**:
- Update Firestore security rules (copy from FIREBASE_SETUP.md)
- Ensure user is authenticated

### Issue: Build fails
**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

## 📚 Documentation Routes

- **Setup Help?** → See `FIREBASE_SETUP.md`
- **Understanding Code?** → See `API_REFERENCE.md`
- **How the app works?** → See `ARCHITECTURE.md`
- **Using the app?** → See `README.md`
- **What's new?** → See `CHANGELOG.md`

## 🎓 First-Time Developer Tips

### 1. Understanding the Code
- Models (`models/`) define data structure
- Providers (`providers/`) manage state
- Screens (`screens/`) create UI
- Routes (`routes/`) handle navigation

### 2. Making Your First Change
1. Edit a string in a screen
   - Find text in `lib/screens/home/home_screen.dart`
   - Change it to your message
2. Save file
3. Hot reload: Press `r` in terminal

### 3. Adding a New Screen
1. Create file: `lib/screens/new_feature/new_screen.dart`
2. Create StatelessWidget class
3. Build the UI
4. Add route to `lib/routes/app_router.dart`

## 🔗 Useful Links

| Resource | Link |
|----------|------|
| Flutter Docs | https://flutter.dev/docs |
| Firebase Docs | https://firebase.google.com/docs |
| Dart Docs | https://dart.dev/guides |
| Material Design | https://m3.material.io |
| VS Code | https://code.visualstudio.com |

## 🎯 Next Steps

### After Getting It Running
1. **Explore**: Try all features in the app
2. **Read**: Check documentation files
3. **Customize**: Change colors, add your features
4. **Test**: Try complex workflows
5. **Deploy**: Build for release

### Development Path
1. Understand current architecture
2. Make small modifications
3. Add simple new features
4. Develop complex features
5. Deploy to app stores

## ⚡ Pro Tips

### Hot Reload
- Press `r` in terminal for fast reload
- Press `R` for full restart

### Debugging
- Add `print()` statements for debugging
- Use DevTools: `flutter devtools`

### Testing
```bash
flutter test              # Run all tests
flutter test lib/        # Test specific folder
```

### Building
```bash
flutter build apk --release      # Build Android APK
flutter build appbundle --release # Build Bundle for Play Store
flutter build ios --release      # Build iOS
```

## 🤝 Getting Help

### If You Get Stuck
1. Check the relevant documentation file
2. Read error message carefully
3. Search [Flutter issues](https://github.com/flutter/flutter/issues)
4. Ask on [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
5. Contact the team

### Reporting Issues
1. Describe the problem clearly
2. Share error messages
3. Provide steps to reproduce
4. Include your setup info

## ✨ Features Included in v1.0.0

- ✅ User authentication
- ✅ Calendar views (month, week, day)
- ✅ Event management (CRUD)
- ✅ Custom categories
- ✅ Family sharing
- ✅ Real-time sync
- ✅ Beautiful UI

## 🚧 Coming Soon

- 🔜 Event editing
- 🔜 Push notifications
- 🔜 To-do lists
- 🔜 Grocery lists
- 🔜 Offline support
- 🔜 Dark theme

## 🎉 Ready to Go!

You now have a fully functional Family Calendar app!

- Try adding events
- Create a family group
- Invite family members
- Customize categories

For detailed feature usage, see **README.md**

---

**Got questions?** Check the docs or reach out to the team! Happy coding! 🚀
