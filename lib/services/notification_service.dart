import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../firebase_options.dart';
import '../models/event_model.dart';
import '../models/todo_list_model.dart';
import '../models/todo_task_model.dart';
import '../models/user_model.dart' as app_user;
import '../utils/constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService extends ChangeNotifier with WidgetsBindingObserver {
  NotificationService() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'family_calendar_general',
    'Family Calendar Notifications',
    description: 'Task, list, assignment, and summary notifications.',
    importance: Importance.high,
  );

  static const int _dailySummaryNotificationId = 9001;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sharedListsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sharedTasksSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _privateTasksSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _familyEventsSubscription;

  app_user.User? _currentUser;
  bool _initialized = false;
  bool _sharedListsPrimed = false;
  bool _sharedTasksPrimed = false;
  bool _privateTasksPrimed = false;
  bool _familyEventsPrimed = false;
  int _notificationSerial = 100;
  Timer? _summaryDebounce;
  Timer? _summaryRescheduleTimer;
  final Map<String, List<String>> _knownTaskAssignees = {};
  bool _notificationsAuthorized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(settings);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_defaultChannel);

    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(_persistFcmToken);

    _initialized = true;
  }

  Future<void> syncSession(app_user.User? user) async {
    await initialize();

    final previousUser = _currentUser;
    _currentUser = user;

    if (user == null) {
      await _cancelDailySummary();
      _cancelLiveSubscriptions();
      return;
    }

    final identityChanged =
        previousUser?.uid != user.uid || previousUser?.familyId != user.familyId;
    final prefsChanged =
        previousUser?.notificationPreferences != user.notificationPreferences;

    await _requestPermissionsIfNeeded(user.notificationPreferences);
    await _persistFcmToken(await _messaging.getToken());

    if (identityChanged) {
      _startLiveSubscriptions();
    }

    if (identityChanged || prefsChanged) {
      await _scheduleDailySummaryIfNeeded();
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _requestPermissionsIfNeeded(
    app_user.NotificationPreferences prefs,
  ) async {
    final wantsNotifications = prefs.notifyOnNewFamilyList ||
        prefs.notifyOnNewFamilyTask ||
        prefs.notifyOnTaskAssignedToMe ||
        prefs.notifyDailyMorningSummary;

    if (!wantsNotifications) {
      _notificationsAuthorized = false;
      return;
    }

    final messagingSettings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final androidGranted = await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iosGranted = await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _notificationsAuthorized =
        messagingSettings.authorizationStatus == AuthorizationStatus.authorized ||
            messagingSettings.authorizationStatus ==
                AuthorizationStatus.provisional ||
            (Platform.isAndroid && androidGranted != false) ||
            (Platform.isIOS && iosGranted == true);
  }

  Future<bool> sendTestNotification() async {
    await initialize();

    final settings = await _messaging.getNotificationSettings();
    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional ||
            (Platform.isAndroid && _notificationsAuthorized);

    if (!isAuthorized) {
      return false;
    }

    await _showLocalNotification(
      title: 'Notifications are working',
      body: 'Family Calendar can now alert you on this device.',
    );
    return true;
  }

  void _startLiveSubscriptions() {
    _cancelLiveSubscriptions();
    _knownTaskAssignees.clear();
    _sharedListsPrimed = false;
    _sharedTasksPrimed = false;
    _privateTasksPrimed = false;
    _familyEventsPrimed = false;

    final user = _currentUser;
    if (user == null) {
      return;
    }

    if (user.familyId != null) {
      _sharedListsSubscription = _firestore
          .collection(AppConstants.todoListsCollection)
          .where('familyId', isEqualTo: user.familyId)
          .where('visibility', isEqualTo: TodoListVisibility.shared.name)
          .snapshots()
          .listen(_handleSharedListsSnapshot);

      _sharedTasksSubscription = _firestore
          .collection(AppConstants.todoTasksCollection)
          .where('familyId', isEqualTo: user.familyId)
          .where('visibility', isEqualTo: TodoListVisibility.shared.name)
          .snapshots()
          .listen(_handleSharedTasksSnapshot);

      _familyEventsSubscription = _firestore
          .collection(AppConstants.eventsCollection)
          .where('familyId', isEqualTo: user.familyId)
          .snapshots()
          .listen(_handleFamilyEventsSnapshot);
    }

    _privateTasksSubscription = _firestore
        .collection(AppConstants.todoTasksCollection)
        .where('ownerUserId', isEqualTo: user.uid)
        .snapshots()
        .listen(_handlePrivateTasksSnapshot);
  }

  void _handleSharedListsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    if (!_sharedListsPrimed) {
      _sharedListsPrimed = true;
      _queueSummaryRefresh();
      return;
    }

    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) {
        continue;
      }

      final list = TodoList.fromFirestore(change.doc);
      if (!user.notificationPreferences.notifyOnNewFamilyList) {
        continue;
      }
      if (list.ownerUserId == user.uid) {
        continue;
      }

      _showLocalNotification(
        title: 'New family list',
        body: '"${list.title}" was added to your shared family lists.',
      );
    }

    _queueSummaryRefresh();
  }

  void _handleSharedTasksSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    if (!_sharedTasksPrimed) {
      for (final doc in snapshot.docs) {
        final task = TodoTask.fromFirestore(doc);
        _knownTaskAssignees[task.id] = List<String>.from(task.assigneeIds);
      }
      _sharedTasksPrimed = true;
      _queueSummaryRefresh();
      return;
    }

    for (final change in snapshot.docChanges) {
      final task = TodoTask.fromFirestore(change.doc);
      final previousAssignees = _knownTaskAssignees[task.id] ?? const [];
      final currentlyAssignedToUser = task.assigneeIds.contains(user.uid);
      final previouslyAssignedToUser = previousAssignees.contains(user.uid);

      if (change.type == DocumentChangeType.removed) {
        _knownTaskAssignees.remove(task.id);
        continue;
      }

      if (change.type == DocumentChangeType.added) {
        if (task.createdBy != user.uid) {
          if (currentlyAssignedToUser &&
              user.notificationPreferences.notifyOnTaskAssignedToMe) {
            _showLocalNotification(
              title: 'Task assigned to you',
              body: '"${task.title}" is now assigned to you.',
            );
          } else if (user.notificationPreferences.notifyOnNewFamilyTask) {
            _showLocalNotification(
              title: 'New family task',
              body: '"${task.title}" was added to a family list.',
            );
          }
        }
      }

      if (change.type == DocumentChangeType.modified &&
          task.createdBy != user.uid &&
          !previouslyAssignedToUser &&
          currentlyAssignedToUser &&
          user.notificationPreferences.notifyOnTaskAssignedToMe) {
        _showLocalNotification(
          title: 'Task assigned to you',
          body: '"${task.title}" is now assigned to you.',
        );
      }

      _knownTaskAssignees[task.id] = List<String>.from(task.assigneeIds);
    }

    _queueSummaryRefresh();
  }

  void _handlePrivateTasksSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!_privateTasksPrimed) {
      _privateTasksPrimed = true;
      _queueSummaryRefresh();
      return;
    }

    _queueSummaryRefresh();
  }

  void _handleFamilyEventsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!_familyEventsPrimed) {
      _familyEventsPrimed = true;
      _queueSummaryRefresh();
      return;
    }

    _queueSummaryRefresh();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    _showLocalNotification(
      title: notification.title ?? 'Family Calendar',
      body: notification.body ?? 'You have a new update.',
    );
  }

  Future<void> _persistFcmToken(String? token) async {
    final user = _currentUser;
    if (user == null || token == null || token.trim().isEmpty) {
      return;
    }

    try {
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(
        {
          'fcmToken': token.trim(),
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    await _localNotifications.show(
      _notificationSerial++,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _queueSummaryRefresh() {
    final prefs = _currentUser?.notificationPreferences;
    if (prefs == null || !prefs.notifyDailyMorningSummary) {
      return;
    }

    _summaryDebounce?.cancel();
    _summaryDebounce = Timer(const Duration(seconds: 2), () async {
      await _scheduleDailySummaryIfNeeded();
    });
  }

  Future<void> _scheduleDailySummaryIfNeeded() async {
    final user = _currentUser;
    final prefs = user?.notificationPreferences;
    if (user == null || prefs == null || !prefs.notifyDailyMorningSummary) {
      await _cancelDailySummary();
      return;
    }

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      prefs.dailySummaryHour,
      prefs.dailySummaryMinute,
    );
    var summaryDate = DateTime(now.year, now.month, now.day);

    if (!scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
      summaryDate = summaryDate.add(const Duration(days: 1));
    }

    final summary = await _buildDailySummary(summaryDate);
    final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

    await _localNotifications.cancel(_dailySummaryNotificationId);
    await _localNotifications.zonedSchedule(
      _dailySummaryNotificationId,
      summary.title,
      summary.body,
      scheduledTz,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(summary.body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    _summaryRescheduleTimer?.cancel();
    final delay = scheduledTime
        .add(const Duration(minutes: 2))
        .difference(DateTime.now());
    if (!delay.isNegative) {
      _summaryRescheduleTimer = Timer(delay, () async {
        await _scheduleDailySummaryIfNeeded();
      });
    }
  }

  Future<_DailySummaryMessage> _buildDailySummary(DateTime date) async {
    final user = _currentUser;
    if (user == null) {
      return const _DailySummaryMessage(
        title: 'Daily summary',
        body: 'Open Family Calendar to review today\'s schedule.',
      );
    }

    final day = DateTime(date.year, date.month, date.day);
    final tasks = await _loadTasksForDay(user: user, day: day);
    final events = await _loadEventsForDay(user: user, day: day);

    final title = 'Daily summary';
    if (tasks.isEmpty && events.isEmpty) {
      return const _DailySummaryMessage(
        title: 'Daily summary',
        body: 'No events or tasks are due today.',
      );
    }

    final eventCount = events.length;
    final taskCount = tasks.length;
    final highlights = <String>[
      ...events.take(2).map((event) => event.title),
      ...tasks.take(2).map((task) => task.title),
    ];

    final body = StringBuffer()
      ..write('$eventCount event${eventCount == 1 ? '' : 's'}')
      ..write(' and ')
      ..write('$taskCount task${taskCount == 1 ? '' : 's'}')
      ..write(' due today.');

    if (highlights.isNotEmpty) {
      body.write(' ');
      body.write('Highlights: ${highlights.join(', ')}.');
    }

    return _DailySummaryMessage(title: title, body: body.toString());
  }

  Future<List<TodoTask>> _loadTasksForDay({
    required app_user.User user,
    required DateTime day,
  }) async {
    final tasks = <String, TodoTask>{};

    final privateSnapshot = await _firestore
        .collection(AppConstants.todoTasksCollection)
        .where('ownerUserId', isEqualTo: user.uid)
        .get();
    for (final doc in privateSnapshot.docs) {
      final task = TodoTask.fromFirestore(doc);
      if (_isTaskDueOnDay(task, day)) {
        tasks[task.id] = task;
      }
    }

    if (user.familyId != null) {
      final sharedSnapshot = await _firestore
          .collection(AppConstants.todoTasksCollection)
          .where('familyId', isEqualTo: user.familyId)
          .get();
      for (final doc in sharedSnapshot.docs) {
        final task = TodoTask.fromFirestore(doc);
        if (_isTaskDueOnDay(task, day)) {
          tasks[task.id] = task;
        }
      }
    }

    final values = tasks.values.toList()
      ..sort((a, b) {
        final aDue = a.dueDate ?? DateTime(9999, 1, 1);
        final bDue = b.dueDate ?? DateTime(9999, 1, 1);
        return aDue.compareTo(bDue);
      });
    return values;
  }

  bool _isTaskDueOnDay(TodoTask task, DateTime day) {
    if (task.isCompleted || task.dueDate == null) {
      return false;
    }

    final due = task.dueDate!;
    return due.year == day.year && due.month == day.month && due.day == day.day;
  }

  Future<List<CalendarEvent>> _loadEventsForDay({
    required app_user.User user,
    required DateTime day,
  }) async {
    final events = <String, CalendarEvent>{};

    if (user.familyId != null) {
      final familySnapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('familyId', isEqualTo: user.familyId)
          .get();
      for (final doc in familySnapshot.docs) {
        final event = CalendarEvent.fromFirestore(doc);
        if (event.occursOnDate(day)) {
          events[event.id] = event;
        }
      }
    }

    final createdSnapshot = await _firestore
        .collection(AppConstants.eventsCollection)
        .where('createdBy', isEqualTo: user.uid)
        .get();
    for (final doc in createdSnapshot.docs) {
      final event = CalendarEvent.fromFirestore(doc);
      if (event.occursOnDate(day)) {
        events[event.id] = event;
      }
    }

    final values = events.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return values;
  }

  Future<void> _cancelDailySummary() async {
    _summaryDebounce?.cancel();
    _summaryRescheduleTimer?.cancel();
    await _localNotifications.cancel(_dailySummaryNotificationId);
  }

  void _cancelLiveSubscriptions() {
    _sharedListsSubscription?.cancel();
    _sharedTasksSubscription?.cancel();
    _privateTasksSubscription?.cancel();
    _familyEventsSubscription?.cancel();
    _sharedListsSubscription = null;
    _sharedTasksSubscription = null;
    _privateTasksSubscription = null;
    _familyEventsSubscription = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _queueSummaryRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _cancelLiveSubscriptions();
    _summaryDebounce?.cancel();
    _summaryRescheduleTimer?.cancel();
    super.dispose();
  }
}

class _DailySummaryMessage {
  final String title;
  final String body;

  const _DailySummaryMessage({
    required this.title,
    required this.body,
  });
}
