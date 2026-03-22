# API Reference Guide

## Overview
This document provides detailed API documentation for the Family Calendar app's main components, services, and utilities.

## Table of Contents
1. [Models](#models)
2. [Providers](#providers)
3. [Services](#services)
4. [UI Components](#ui-components)
5. [Utilities](#utilities)

---

## Models

### User Model
Represents a user account in the system.

```dart
class User {
  final String uid;              // Firebase Auth UID
  final String email;            // Email address
  final String displayName;      // Display name
  final String photoUrl;         // Profile photo URL
  final String role;             // 'admin' or 'member'
  final String? familyId;        // Family group ID
  final DateTime createdAt;      // Account creation time
  final DateTime updatedAt;      // Last update time
}
```

**Key Methods:**
- `User.fromFirestore(DocumentSnapshot doc)` - Create from Firestore
- `Map<String, dynamic> toFirestore()` - Convert to Firestore format
- `User copyWith({...})` - Create modified copy

---

### EventCategory Model
Represents a custom event category.

```dart
class EventCategory {
  final String id;               // Unique category ID
  final String familyId;         // Family this belongs to
  final String name;             // Category name
  final String? icon;            // Category icon/emoji
  final int colorValue;          // Color as integer
  final String? description;     // Optional description
  final DateTime createdAt;      // Creation time
  final DateTime updatedAt;      // Last update time
}
```

**Key Methods:**
- `Color get color` - Returns Color from colorValue
- `EventCategory.fromFirestore(DocumentSnapshot doc)` - Create from Firestore
- `EventCategory copyWith({...})` - Create modified copy

---

### CalendarEvent Model
Represents a calendar event.

```dart
class CalendarEvent {
  final String id;               // Unique event ID
  final String familyId;         // Family this belongs to
  final String title;            // Event title
  final String? description;     // Event description
  final DateTime date;           // Event date
  final DateTime? startTime;     // Event start time
  final DateTime? endTime;       // Event end time
  final String categoryId;       // Category ID
  final String? location;        // Event location
  final String? notes;           // Additional notes
  final String? assignedToUserId; // Assigned user
  final List<String> attendeeIds; // Attendees
  final RecurrenceType recurrence; // Recurrence type
  final DateTime? recurrenceEndDate; // Recurrence end
  final bool allDay;             // Is all-day event
  final String? imageUrl;        // Event image URL
  final DateTime createdAt;      // Creation time
  final DateTime updatedAt;      // Last update time
  final String createdBy;        // Creator's UID
}
```

**Key Methods:**
- `CalendarEvent.fromFirestore(DocumentSnapshot doc)` - Create from Firestore
- `CalendarEvent copyWith({...})` - Create modified copy

---

### Family Model
Represents a family group.

```dart
class Family {
  final String id;               // Unique family ID
  final String name;             // Family name
  final String adminId;          // Admin user's UID
  final List<String> memberIds;  // All member UIDs
  final List<String> pendingInvites; // Pending invite emails
  final String? description;     // Family description
  final String? photoUrl;        // Family photo
  final DateTime createdAt;      // Creation time
  final DateTime updatedAt;      // Last update time
}
```

**Key Methods:**
- `Family.fromFirestore(DocumentSnapshot doc)` - Create from Firestore
- `Family copyWith({...})` - Create modified copy

---

## Providers

### AuthProvider
Handles authentication and user management.

**State Properties:**
```dart
app_user.User? get currentUser      // Currently logged-in user
bool get isLoading                  // Is loading
String? get errorMessage            // Current error
bool get isAuthenticated           // Is user logged in
```

**Key Methods:**

#### `Future<void> signUp({...})`
Create a new user account.

**Parameters:**
- `email` (String, required): User's email
- `password` (String, required): User's password
- `displayName` (String, required): User's display name

**Returns:** Future that completes when signup is done

**Example:**
```dart
final authProvider = context.read<AuthProvider>();
await authProvider.signUp(
  email: 'user@example.com',
  password: 'securePassword123',
  displayName: 'John Doe',
);
```

#### `Future<void> signIn({...})`
Sign in with email and password.

**Parameters:**
- `email` (String, required): User's email
- `password` (String, required): User's password

**Example:**
```dart
await authProvider.signIn(
  email: 'user@example.com',
  password: 'securePassword123',
);
```

#### `Future<void> signOut()`
Sign out the current user.

**Example:**
```dart
await authProvider.signOut();
```

#### `Future<void> updateProfile({...})`
Update user profile information.

**Parameters:**
- `displayName` (String?, optional): New display name
- `photoUrl` (String?, optional): New photo URL

**Example:**
```dart
await authProvider.updateProfile(
  displayName: 'Jane Doe',
  photoUrl: 'https://example.com/photo.jpg',
);
```

#### `Future<void> resetPassword(String email)`
Send password reset email.

**Parameters:**
- `email` (String, required): Email to send reset link

**Example:**
```dart
await authProvider.resetPassword('user@example.com');
```

---

### EventProvider
Manages events.

**State Properties:**
```dart
List<CalendarEvent> get events    // All events
bool get isLoading                // Is loading
String? get errorMessage          // Current error
```

**Key Methods:**

#### `Future<void> loadEvents(String familyId)`
Load all events for a family.

**Parameters:**
- `familyId` (String, required): Family ID to load events for

#### `Future<void> addEvent({...})`
Create a new event.

**Parameters:**
- `familyId` (String, required): Family ID
- `title` (String, required): Event title
- `date` (DateTime, required): Event date
- `categoryId` (String, required): Category ID
- `createdBy` (String, required): Creator's UID
- `description` (String?, optional): Event description
- `startTime` (DateTime?, optional): Start time
- `endTime` (DateTime?, optional): End time
- `location` (String?, optional): Event location
- `notes` (String?, optional): Notes
- `assignedToUserId` (String?, optional): Assigned user
- `attendeeIds` (List<String>?, optional): Attendees
- `allDay` (bool?, optional): Is all-day (default: false)

**Example:**
```dart
await eventProvider.addEvent(
  familyId: 'family123',
  title: 'Soccer Practice',
  date: DateTime(2026, 3, 25),
  categoryId: 'sports123',
  createdBy: 'user123',
  startTime: DateTime(2026, 3, 25, 16, 0),
  endTime: DateTime(2026, 3, 25, 17, 30),
  location: 'Soccer Field',
);
```

#### `Future<void> updateEvent({...})`
Update an existing event.

**Parameters:**
- `eventId` (String, required): Event ID to update
- All other parameters are optional and will only update if provided

#### `Future<void> deleteEvent(String eventId)`
Delete an event.

**Parameters:**
- `eventId` (String, required): Event ID to delete

#### `Future<void> duplicateEvent(CalendarEvent event)`
Create a duplicate of an event one day later.

**Parameters:**
- `event` (CalendarEvent, required): Event to duplicate

#### `List<CalendarEvent> getEventsForDate(DateTime date)`
Get all events for a specific date.

**Parameters:**
- `date` (DateTime, required): Date to query

**Returns:** List of events on that date

#### `List<CalendarEvent> getEventsForMonth(DateTime date)`
Get all events in a month.

**Parameters:**
- `date` (DateTime, required): Date in the month

**Returns:** List of events in that month

#### `CalendarEvent? getEventById(String id)`
Get a specific event by ID.

**Parameters:**
- `id` (String, required): Event ID

**Returns:** Event or null if not found

---

### CategoryProvider
Manages event categories.

**State Properties:**
```dart
List<EventCategory> get categories // All categories
bool get isLoading                 // Is loading
String? get errorMessage           // Current error
```

**Key Methods:**

#### `Future<void> loadCategories(String familyId)`
Load all categories for a family.

**Parameters:**
- `familyId` (String, required): Family ID

#### `Future<void> addCategory({...})`
Create a new category.

**Parameters:**
- `familyId` (String, required): Family ID
- `name` (String, required): Category name
- `color` (Color, required): Category color
- `icon` (String?, optional): Category icon
- `description` (String?, optional): Description

#### `Future<void> updateCategory({...})`
Update an existing category.

**Parameters:**
- `categoryId` (String, required): Category ID to update
- `name` (String, required): New name
- `color` (Color, required): New color
- `icon` (String?, optional): New icon
- `description` (String?, optional): New description

#### `Future<void> deleteCategory(String categoryId)`
Delete a category.

**Parameters:**
- `categoryId` (String, required): Category ID to delete

#### `EventCategory? getCategoryById(String id)`
Get a category by ID.

**Parameters:**
- `id` (String, required): Category ID

**Returns:** Category or null if not found

---

### FamilyProvider
Manages family groups and members.

**State Properties:**
```dart
Family? get currentFamily          // Current family
List<User> get familyMembers       // Family members
bool get isLoading                 // Is loading
String? get errorMessage           // Current error
```

**Key Methods:**

#### `Future<void> createFamily({...})`
Create a new family.

**Parameters:**
- `adminId` (String, required): Admin's UID
- `familyName` (String, required): Family name
- `description` (String?, optional): Family description

#### `Future<void> loadFamily(String familyId)`
Load family data and members.

**Parameters:**
- `familyId` (String, required): Family ID to load

#### `Future<void> inviteMember({...})`
Send invitation to family member.

**Parameters:**
- `familyId` (String, required): Family ID
- `emailToInvite` (String, required): Email to invite

#### `Future<void> addMember({...})`
Add a member to family.

**Parameters:**
- `familyId` (String, required): Family ID
- `userId` (String, required): User ID to add
- `role` (String?, optional): User role (default: 'member')

#### `Future<void> removeMember({...})`
Remove a member from family.

**Parameters:**
- `familyId` (String, required): Family ID
- `userId` (String, required): User ID to remove

#### `Future<void> updateFamily({...})`
Update family information.

**Parameters:**
- `familyId` (String, required): Family ID
- `name` (String, required): New family name
- `description` (String?, optional): New description
- `photoUrl` (String?, optional): New photo URL

---

## Services

### NotificationService (Planned)
Handles push notifications and reminders.

**Key Methods:**
- `Future<void> initializeNotifications()` - Initialize notification service
- `Future<void> scheduleEventReminder(CalendarEvent event)` - Schedule reminder
- `Future<void> cancelReminder(String eventId)` - Cancel reminder

---

## UI Components

### LoginScreen
Handles user login functionality.

**Input Fields:**
- Email (validated)
- Password (hidden by default)

**Actions:**
- Sign In button
- Link to Sign Up

---

### SignupScreen
Handles user registration.

**Input Fields:**
- Display Name
- Email
- Password
- Confirm Password

**Validations:**
- All fields required
- Passwords must match
- Password minimum length: 6 characters

---

### CalendarScreen
Display and interact with calendar.

**Features:**
- Monthly/weekly/daily views
- Color-coded events
- Date navigation
- Event listing for selected day

---

### AddEventScreen
Create new events.

**Input Fields:**
- Event Title (required)
- Date (required, date picker)
- Time (optional, time picker)
- All Day toggle
- Location (optional)
- Notes (optional)
- Category (required, dropdown)

---

### EventDetailScreen
View event details.

**Information Displayed:**
- Event title and category
- Date and time
- Location
- Assigned user
- Notes
- Created date

**Actions:**
- Edit event (coming soon)
- Delete event
- Duplicate event

---

## Utilities

### Constants
Global constants and configuration values.

**Usage:**
```dart
import 'package:family_calendar/utils/constants.dart';

// Access constants
String appName = AppConstants.appName;
int maxEventTitleLength = AppConstants.maxEventTitleLength;
Color primaryColor = Color(ColorConstants.primaryColor);
```

---

## Error Handling

All providers include error handling with `errorMessage` property:

```dart
Consumer<EventProvider>(
  builder: (context, eventProvider, _) {
    if (eventProvider.errorMessage != null) {
      return Text('Error: ${eventProvider.errorMessage}');
    }
    // Show content
  },
)
```

---

## Firestore Query Patterns

### Query Events by Family
```dart
await FirebaseFirestore.instance
    .collection('events')
    .where('familyId', isEqualTo: familyId)
    .orderBy('date')
    .get();
```

### Query Events by Month
```dart
final startOfMonth = DateTime(year, month, 1);
final endOfMonth = DateTime(year, month + 1, 0);

await FirebaseFirestore.instance
    .collection('events')
    .where('familyId', isEqualTo: familyId)
    .where('date', isGreaterThanOrEqualTo: startOfMonth)
    .where('date', isLessThanOrEqualTo: endOfMonth)
    .orderBy('date')
    .get();
```

### Query Categories by Family
```dart
await FirebaseFirestore.instance
    .collection('categories')
    .where('familyId', isEqualTo: familyId)
    .get();
```

---

## Best Practices

### 1. Always use Provider for State
```dart
// Good
context.read<EventProvider>().addEvent(...)

// Avoid
// Direct Firestore access in UI
```

### 2. Handle Loading States
```dart
Consumer<EventProvider>(
  builder: (context, provider, _) {
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    // Show content
  },
)
```

### 3. Validate User Input
```dart
if (titleController.text.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Enter event title')),
  );
  return;
}
```

### 4. Dispose Controllers
```dart
@override
void dispose() {
  titleController.dispose();
  super.dispose();
}
```

---

## Common Use Cases

### Create an Event
```dart
final eventProvider = context.read<EventProvider>();
final authProvider = context.read<AuthProvider>();

await eventProvider.addEvent(
  familyId: authProvider.currentUser!.familyId!,
  title: 'Soccer Game',
  date: DateTime(2026, 3, 25),
  categoryId: 'sports123',
  createdBy: authProvider.currentUser!.uid,
  startTime: DateTime(2026, 3, 25, 10, 0),
  endTime: DateTime(2026, 3, 25, 11, 30),
  location: 'City Park',
);
```

### Get Events for a Date
```dart
List<CalendarEvent> todayEvents = 
    eventProvider.getEventsForDate(DateTime.now());
```

### Update an Event
```dart
await eventProvider.updateEvent(
  eventId: 'event123',
  title: 'Updated Title',
  location: 'New Location',
);
```

---

## API Versioning

**Current Version**: 1.0.0

Breaking changes will be documented in CHANGELOG.md
