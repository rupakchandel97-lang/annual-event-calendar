/// Application constants
class AppConstants {
  // App metadata
  static const String appName = 'Family Calendar';
  static const String appVersion = '1.0.0';
  static const String appAuthor = 'Family Calendar Team';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String familiesCollection = 'families';
  static const String eventsCollection = 'events';
  static const String categoriesCollection = 'categories';
  static const String todoListsCollection = 'todo_lists';
  static const String todoTasksCollection = 'todo_tasks';
  static const String shoppingListsCollection = 'shopping_lists';
  static const String shoppingItemsCollection = 'shopping_items';
  static const String shoppingHistoryCollection = 'shopping_history';
  static const String inventoryItemsCollection = 'inventory_items';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleMember = 'member';

  // Event types
  static const String eventTypeNone = 'none';
  static const String eventTypeDaily = 'daily';
  static const String eventTypeWeekly = 'weekly';
  static const String eventTypeMonthly = 'monthly';
  static const String eventTypeYearly = 'yearly';

  // Default categories
  static final List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Sports', 'color': 0xFF4CAF50, 'icon': '⚽'},
    {'name': 'School', 'color': 0xFF2196F3, 'icon': '📚'},
    {'name': 'Birthday', 'color': 0xFFFF9800, 'icon': '🎂'},
    {'name': 'Holiday', 'color': 0xFFE91E63, 'icon': '🎉'},
    {'name': 'Doctor', 'color': 0xFFF44336, 'icon': '⚕️'},
    {'name': 'Entertainment', 'color': 0xFF9C27B0, 'icon': '🎭'},
    {'name': 'Work', 'color': 0xFF00BCD4, 'icon': '💼'},
    {'name': 'Shopping', 'color': 0xFFFFEB3B, 'icon': '🛍️'},
  ];

  // Notification settings
  static const int notificationWarning10Minutes = 10;
  static const int notificationWarning1Hour = 60;
  static const int notificationWarning1Day = 1440;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 4.0;

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Text field validation
  static const int minPasswordLength = 6;
  static const int maxEventTitleLength = 100;
  static const int maxEventNotesLength = 500;

  // Firestore limits
  static const int maxEventsPerDay = 20;
  static const int maxFamilyMembers = 50;

  // Error messages
  static const String errorGeneric = 'An error occurred. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuthentication = 'Authentication failed. Please try again.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorPasswordTooShort = 'Password must be at least 6 characters.';
  static const String errorEmailAlreadyInUse = 'This email is already registered.';
  static const String errorWeakPassword = 'Password is too weak.';
  static const String errorOperationFailed = 'Operation failed. Please try again.';

  // Success messages
  static const String successEventCreated = 'Event created successfully';
  static const String successEventUpdated = 'Event updated successfully';
  static const String successEventDeleted = 'Event deleted successfully';
  static const String successCategoryAdded = 'Category added successfully';
  static const String successMemberAdded = 'Member added successfully';
  static const String successInvitationSent = 'Invitation sent successfully';

  // Date & Time formats
  static const String dateFormatShort = 'MMM d';
  static const String dateFormatMedium = 'MMM d, yyyy';
  static const String dateFormatLong = 'EEEE, MMMM d, yyyy';
  static const String timeFormat24 = 'HH:mm';
  static const String timeFormat12 = 'hh:mm a';

  // Empty states
  static const String emptyEventsMessage = 'No events scheduled';
  static const String emptyCategoriesMessage = 'No categories yet';
  static const String emptyMembersMessage = 'No family members';

  // Route names (for named navigation)
  static const String routeLogin = 'login';
  static const String routeSignup = 'signup';
  static const String routeHome = 'home';
  static const String routeCalendar = 'calendar';
  static const String routeAddEvent = 'addEvent';
  static const String routeEventDetail = 'eventDetail';
  static const String routeSettings = 'settings';
  static const String routeCategorySettings = 'categorySettings';
  static const String routeFamilyMembers = 'familyMembers';

  // Profile defaults
  static const String defaultPhotoUrl = '';
  static const String defaultDisplayName = 'User';

  // Batch operations
  static const int batchSize = 25; // Firestore batch write limit
}

/// Duration constants for animations and timeouts
class DurationConstants {
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration toastDuration = Duration(milliseconds: 1500);
  static const Duration dialogAnimationDuration = Duration(milliseconds: 300);
  static const Duration navigationAnimationDuration = Duration(milliseconds: 250);
}

/// Size constants for UI
class SizeConstants {
  static const double buttonHeight = 50.0;
  static const double textFieldHeight = 56.0;
  static const double iconSize = 24.0;
  static const double avatarRadius = 20.0;
  static const double largeAvatarRadius = 40.0;
  static const double cardElevation = 2.0;
  static const double borderWidth = 1.0;
}

/// Color constants (using hex values that can be converted to Color)
class ColorConstants {
  static const int primaryColor = 0xFF2196F3;
  static const int secondaryColor = 0xFF03DAC6;
  static const int errorColor = 0xFFB00020;
  static const int warningColor = 0xFFFFB300;
  static const int successColor = 0xFF4CAF50;
  static const int surfaceColor = 0xFFFAFAFA;
}
