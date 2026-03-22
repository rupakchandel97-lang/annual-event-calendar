# Family Calendar Android App - Architecture & Documentation

## Project Overview
A beautiful family calendar app with shared event management, inspired by Cozi and Skylight. Built with Flutter and Firebase.

## Technology Stack
- **Frontend**: Flutter 3.0+
- **Backend**: Firebase (Auth, Firestore, Messaging, Storage)
- **State Management**: Provider
- **Navigation**: GoRouter
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth (Email/Password)
- **Notifications**: Firebase Cloud Messaging

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── models/                            # Data models
│   ├── user_model.dart
│   ├── event_model.dart
│   ├── category_model.dart
│   └── family_model.dart
├── providers/                         # State management
│   ├── auth_provider.dart
│   ├── event_provider.dart
│   ├── category_provider.dart
│   └── family_provider.dart
├── routes/
│   └── app_router.dart               # Navigation routes
├── screens/                           # UI Screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── calendar/
│   │   └── calendar_screen.dart
│   ├── event/
│   │   ├── add_event_screen.dart
│   │   └── event_detail_screen.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   └── category_settings_screen.dart
│   └── family/
│       └── family_members_screen.dart
├── services/                          # Business logic
│   ├── notification_service.dart
│   └── storage_service.dart
└── utils/                             # Utilities
    └── constants.dart
```

## Core Features

### 1. Authentication
- Email-based login/signup
- Firebase Authentication
- User profile management
- Role-based access (Admin/Member)

### 2. Calendar Management
- Monthly, weekly, daily views
- Event visualization with color-coded categories
- Drag & drop events (advanced)
- Quick event creation from date tap

### 3. Event Management
- Create, read, update, delete events
- Event fields: title, date/time, location, notes, category, attendees
- Recurring event support
- Event duplication
- Assign events to family members

### 4. Category System
- Create custom categories with colors and icons
- Default categories provided
- Category-based event filtering
- Admin-only management

### 5. Family Sharing
- Create family groups
- Add/invite family members
- Role-based permissions
- Share calendar across family

### 6. Notifications (Planned)
- Push notifications for events
- Configurable reminders (10 min, 1 hr, 1 day before)
- Daily summary option

## Data Models

### User
```dart
class User {
  String uid
  String email
  String displayName
  String photoUrl
  String role                    // 'admin' or 'member'
  String? familyId
  DateTime createdAt
  DateTime updatedAt
}
```

### Family
```dart
class Family {
  String id
  String name
  String adminId
  List<String> memberIds
  List<String> pendingInvites
  String? description
  String? photoUrl
  DateTime createdAt
  DateTime updatedAt
}
```

### EventCategory
```dart
class EventCategory {
  String id
  String familyId
  String name
  String? icon
  int colorValue              // Stored as int, converted to Color
  String? description
  DateTime createdAt
  DateTime updatedAt
}
```

### CalendarEvent
```dart
class CalendarEvent {
  String id
  String familyId
  String title
  String? description
  DateTime date
  DateTime? startTime
  DateTime? endTime
  String categoryId
  String? location
  String? notes
  String? assignedToUserId
  List<String> attendeeIds
  RecurrenceType recurrence
  DateTime? recurrenceEndDate
  bool allDay
  String? imageUrl
  DateTime createdAt
  DateTime updatedAt
  String createdBy
}
```

## Firestore Schema

### Collections Structure

```
/users/{uid}
  - email: string
  - displayName: string
  - photoUrl: string
  - role: string (admin | member)
  - familyId: string (nullable)
  - createdAt: timestamp
  - updatedAt: timestamp

/families/{familyId}
  - name: string
  - adminId: string
  - memberIds: array
  - pendingInvites: array
  - description: string
  - photoUrl: string
  - createdAt: timestamp
  - updatedAt: timestamp

/categories/{categoryId}
  - familyId: string
  - name: string
  - icon: string (nullable)
  - colorValue: number
  - description: string
  - createdAt: timestamp
  - updatedAt: timestamp

/events/{eventId}
  - familyId: string
  - title: string
  - description: string
  - date: timestamp
  - startTime: timestamp (nullable)
  - endTime: timestamp (nullable)
  - categoryId: string
  - location: string (nullable)
  - notes: string (nullable)
  - assignedToUserId: string (nullable)
  - attendeeIds: array
  - recurrence: string (none | daily | weekly | monthly | yearly)
  - recurrenceEndDate: timestamp (nullable)
  - allDay: boolean
  - imageUrl: string (nullable)
  - createdAt: timestamp
  - updatedAt: timestamp
  - createdBy: string
```

### Firestore Indexes
```
- events: familyId + date (for monthly queries)
- categories: familyId
- users: email (for quick lookup during sign up)
```

## State Management (Provider)

### AuthProvider
- Handles authentication state
- Manages user login/signup
- Profile updates
- Password reset

### FamilyProvider
- Manages family data
- Handles member management
- Invitations

### CategoryProvider
- Manages event categories
- CRUD operations
- Default categories

### EventProvider
- Manages events
- Filtering by date/month
- Event CRUD operations
- Duplicate events

## Navigation Routes

```
/login                          # Login screen
/signup                         # Signup screen
/                              # Home (main dashboard)
/calendar                      # Calendar view
/event/add                     # Add event screen
/event/:eventId                # Event details
/settings                      # Settings screen
/settings/categories           # Category management
/family/members                # Family members management
```

## Setup Instructions

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Firebase account
- Android SDK (API 21+) or iOS 11+

### Local Setup

1. **Clone and setup**
```bash
cd family_calendar
flutter pub get
```

2. **Configure Firebase**
- Create Firebase project at https://console.firebase.google.com
- Create web app and get credentials
- Update `lib/firebase_options.dart` with your credentials
- Enable Firestore, Auth, and Messaging

3. **Android Setup**
- Add google-services.json to `android/app/`
- Update build.gradle and settings
- Enable Firebase in Android project

4. **iOS Setup**
- Add GoogleService-Info.plist to Xcode project
- Configure Podfile
- Update Info.plist with necessary permissions

5. **Run the app**
```bash
flutter run
```

## Development Workflow

### Running in Debug Mode
```bash
flutter run
```

### Building for Release
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Running Tests
```bash
flutter test
```

## API Integration Points

### Authentication Flow
```
1. User -> SignupScreen -> AuthProvider.signUp()
2. Create Firebase user
3. Store user document in Firestore
4. User automatically signed in

1. User -> LoginScreen -> AuthProvider.signIn()
2. Firebase authenticates
3. Load user from Firestore
4. Route to HomeScreen
```

### Event Creation Flow
```
1. User -> AddEventScreen
2. Fill event details
3. EventProvider.addEvent()
4. Create event document in Firestore
5. Update local cache
6. Show confirmation
```

### Family Sharing Flow
```
1. Admin invites member
2. FamilyProvider.inviteMember()
3. Add to pendingInvites in Firestore
4. Send email (via Cloud Functions - future)
5. Member accepts and joins family
```

## Security Rules

### Firestore Security Rules
```
match /users/{uid} {
  allow read, update: if request.auth.uid == uid;
  allow create: if request.auth.uid != null;
  allow delete: if false;
}

match /families/{familyId} {
  allow read: if request.auth.uid in resource.data.memberIds;
  allow update: if request.auth.uid == resource.data.adminId;
  allow create: if request.auth != null;
}

match /events/{eventId} {
  allow read: if request.auth.uid != null && 
              exists(/databases/$(database)/documents/families/$(resource.data.familyId)/members/$(request.auth.uid));
  allow create, update: if request.auth.uid != null;
  allow delete: if request.auth.uid == resource.data.createdBy ||
                   request.auth.uid == get(/databases/$(database)/documents/families/$(resource.data.familyId)).data.adminId;
}

match /categories/{categoryId} {
  allow read: if request.auth.uid in get(/databases/$(database)/documents/families/$(resource.data.familyId)).data.memberIds;
  allow write: if request.auth.uid == get(/databases/$(database)/documents/families/$(resource.data.familyId)).data.adminId;
}
```

## Future Enhancements

1. **Advanced Features**
   - Recurring event expansion
   - Drag & drop event management
   - Photo dashboard mode
   - Push notifications with customization
   - Offline sync support

2. **Additional Modules**
   - Shared grocery list
   - To-do lists with task assignment
   - Photo gallery for events
   - Magic email import

3. **UI/UX Improvements**
   - Dark theme support
   - Widget customization
   - Gesture-based controls
   - Accessibility improvements

4. **Performance**
   - Pagination for large event lists
   - Image optimization
   - Caching strategies
   - Background sync

## Troubleshooting

### Firebase Connection Issues
- Verify google-services.json/GoogleService-Info.plist
- Check Firebase project settings
- Ensure correct package name in Firebase console

### Build Issues
- Clean build: `flutter clean && flutter pub get`
- Clear cache: `flutter clean`
- Update dependencies: `flutter pub upgrade`

### Runtime Errors
- Check Firestore security rules
- Verify user authentication status
- Check console logs for detailed errors

## Contributing

1. Create feature branch: `git checkout -b feature/name`
2. Make changes and commit
3. Push and create pull request
4. Follow Flutter best practices and code style

## License
MIT License - See LICENSE file

## Support
For issues and questions, please refer to the project documentation or Firebase docs.
