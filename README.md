# Family Calendar Android App

A beautiful, feature-rich family calendar application built with Flutter and Firebase. Share events with family members, manage schedules together, and stay organized as a family unit.

## ✨ Features

### 📅 Calendar Management
- **Multiple Views**: Monthly, weekly, and daily calendar views
- **Color-Coded Events**: Events automatically colored by category
- **Quick Event Creation**: Tap a date to quickly add an event
- **Event Details**: View comprehensive event information including time, location, and notes

### 👨‍👩‍👧 Family Sharing
- **Family Groups**: Create and manage family calendars
- **Invite Members**: Send email invitations to family members
- **Role-Based Access**: Admin and Member roles with appropriate permissions
- **Member Management**: Add, remove, or manage family members

### 🏷️ Event Categories
- **Custom Categories**: Create categories with custom colors and icons
- **Default Categories**: Pre-loaded with common family event types
- **Easy Management**: Admin can create and manage categories
- **Visual Organization**: Color-coded events for better organization

### 🎯 Event Management
- **Create Events**: Add events with detailed information
  - Title, date, time range
  - Location and notes
  - Category assignment
  - All-day event support
  - Assign to family members
- **Edit Events**: Modify existing events
- **Delete Events**: Remove unwanted events
- **Duplicate Events**: Quickly duplicate events to nearby dates

### 📱 User-Friendly Interface
- **Clean Design**: Intuitive, kid-friendly interface
- **Large Touch Targets**: Optimized for touch devices
- **Dark Mode Support**: Comfortable viewing in any lighting
- **Responsive Layout**: Works on phones and tablets

### 🔐 Security & Authentication
- **Email/Password Auth**: Secure Firebase authentication
- **User Profiles**: Personalized user information
- **Data Encryption**: All data encrypted in transit and at rest
- **Privacy Focused**: Only family members can view shared data

## 📋 System Requirements

### Minimum Requirements
- **Flutter**: 3.0.0 or higher
- **Dart**: 3.0.0 or higher
- **Android**: API 21 (Android 5.0) or higher
- **iOS**: iOS 11.0 or higher

### Development Environment
- Flutter SDK installed
- Xcode (for iOS development)
- Android Studio or Android SDK tools
- Firebase CLI (optional but recommended)

## 🚀 Getting Started

### 1. Prerequisites Installation

#### Install Flutter
```bash
# Download Flutter from https://flutter.dev/docs/get-started/install
# Add to PATH environment variable
flutter --version
dart --version
```

#### Install Dependencies
```bash
# Ensure you have the latest versions
flutter pub global activate fvm  # (Optional: for version management)
```

### 2. Project Setup

#### Clone the Project
```bash
git clone <repository-url>
cd family_calendar
```

#### Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a new project"
3. Enter project name "family-calendar"
4. Enable Google Analytics (optional)
5. Click "Create project"

#### Configure Authentication
1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Select "Email/Password"
4. Click "Enable"
5. Save and continue

#### Configure Firestore
1. Go to **Firestore Database**
2. Click "Create database"
3. Select "Start in test mode" (for development)
4. Choose your region (preferably closest to you)
5. Click "Create database"

#### Set Up Firebase for Android
1. In Firebase Console, go to **Project Settings**
2. Click "Add app" → Select Android
3. Enter package name: `com.example.family_calendar`
4. Click "Register app"
5. Download `google-services.json`
6. Place it in `android/app/google-services.json`

#### Set Up Firebase for iOS
1. In Firebase Console, click "Add app" → Select iOS
2. Enter bundle ID: `com.example.family.calendar`
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Add `GoogleService-Info.plist` to the project
6. Ensure it's added to Runner target

### 4. Update Firebase Configuration

Edit `lib/firebase_options.dart` with your Firebase project credentials:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
);
```

### 5. Run the App

#### Android
```bash
flutter run -d <device_id>
# Or: flutter run (will select a connected device)
```

#### iOS
```bash
flutter run -d <device_id>
# First time setup:
cd ios
pod install
cd ..
flutter run
```

#### Web (for testing)
```bash
flutter run -d chrome
```

## 📖 Usage Guide

### First Time Setup

1. **Sign Up**
   - Open the app
   - Click "Sign Up"
   - Enter your full name, email, and password
   - You'll be set as the family admin

2. **Create Your Family**
   - After signup, the app will initialize a default family
   - You can manage it in Settings → Family Members

3. **Add Categories**
   - Go to Settings → Categories
   - Click "+" to add custom categories
   - Choose colors and names for your family's event types

### Daily Usage

#### Adding an Event
1. Click the **+** button (floating action button)
2. Enter event details:
   - **Event Title**: Required
   - **Date**: Select from date picker
   - **Time**: Set if not an all-day event
   - **Location**: Optional but helpful
   - **Category**: Choose from your categories
   - **Notes**: Add any additional details
3. Click "Save Event"

#### Viewing Your Calendar
1. On Home screen, click "Calendar" tab or "Open Calendar" button
2. Navigate months/weeks using arrows
3. Tap a date to see all events for that day
4. Click an event to view full details

#### Managing Events
- **View Details**: Click on any event
- **Edit**: Coming in next update
- **Delete**: On event detail screen, click delete icon
- **Duplicate**: Use the duplicate function on event detail screen

#### Managing Family
1. Go to Settings → Family Members
2. View all current family members
   - Name, email, and role displayed
3. **Add Members**:
   - Admin only: Click "+" button
   - Enter family member's email
   - Send invitation
4. **Remove Members**: 
   - Admin only: Swipe or click delete on member

#### Managing Categories
1. Go to Settings → Categories
2. View all custom categories
3. **Add Category**:
   - Click "+" button
   - Enter category name
   - Choose a color
   - Click "Add"
4. **Delete Category**:
   - Swipe left on the category
   - Confirm deletion

## 🎨 UI Components Overview

### Navigation
- **Bottom Navigation**: Quick access to Calendar, Agenda, and To-Do views
- **AppBar**: Consistent header with back buttons and actions
- **Floating Action Button**: Quick event creation

### Calendar View
- Monthly grid display
- Color-coded events
- Touch-friendly date cells
- Upcoming events list

### Event Cards
- Visual indicators (colored dots)
- Event title and time
- Quick actions (edit, delete, duplicate)

## 🔒 Data & Privacy

### Data Storage
- All data stored in Firebase Firestore
- Automatic encrypted backup
- Real-time synchronization across devices

### Privacy & Sharing
- Data only accessible to family members
- Admin controls who has access
- No data shared with third parties
- User can revoke access at any time

### Data Deletion
- Delete account in Settings
- All personal data will be removed
- Family admin must remove member to prevent recovery

## 🐛 Troubleshooting

### Firebase Connection Issues
```
Error: "Failed to initialize Firebase"
Solution: 
1. Verify google-services.json is in android/app/
2. Check Firebase project ID is correct
3. Ensure Firebase is enabled in project
```

### Can't Create Family
```
Error: "Family creation failed"
Solution:
1. Ensure you're signed in
2. Check Firestore security rules
3. Verify Firestore database exists
```

### Events Not Showing
```
Error: "Events not appearing on calendar"
Solution:
1. Ensure family is loaded
2. Check app has Firestore read permissions
3. Verify events have correct familyId
```

### Build Errors
```
Clean and rebuild:
flutter clean
flutter pub get
flutter run
```

## 📞 Support & Help

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Provider Package](https://pub.dev/packages/provider)

### Reporting Issues
1. Check the troubleshooting section above
2. Review [GitHub Issues](create-link-to-issues)
3. Contact development team with error details

## 🔄 Update & Maintenance

### Checking for Updates
The app will notify you of available updates. Download directly from:
- Google Play Store (Android)
- Apple App Store (iOS)

### Regular Maintenance
- Back up important events
- Clear old/archived events periodically
- Update family member information as needed

## 📝 Development

### Project Structure
```
lib/
├── models/           # Data models
├── providers/        # State management
├── screens/          # UI screens
├── routes/           # Navigation
└── services/         # Business logic
```

### Adding New Features
1. Create corresponding model in `lib/models/`
2. Add provider in `lib/providers/` for state management
3. Create screen in `lib/screens/`
4. Update routes in `lib/routes/app_router.dart`

### Testing
```bash
flutter test
```

## 👥 Collaboration

### For Team Members
- Clone the repo
- Create a feature branch: `git checkout -b feature/feature-name`
- Make changes following Flutter best practices
- Create a pull request for review

### Code Style
- Follow Flutter style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep functions focused and small

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Cozi Family Organizer and Skylight Calendar
- Built with [Flutter](https://flutter.dev)
- Powered by [Firebase](https://firebase.google.com)
- Icons from [Material Design](https://material.io/icons)

## 📞 Contact

For questions or suggestions, please reach out to the development team.

---

**Version**: 1.0.0  
**Last Updated**: March 2026  
**Status**: Active Development
