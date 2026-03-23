import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clear() {
    _events = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadEvents(String familyId) async {
    await loadEventsForContext(familyId: familyId);
  }

  Future<void> loadEventsForContext({
    required String familyId,
    String? userId,
    String? userEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final mergedEvents = <String, CalendarEvent>{};
      final eventsCollection = _firestore.collection('events');

      final familySnapshot = await eventsCollection
          .where('familyId', isEqualTo: familyId)
          .get();

      for (final doc in familySnapshot.docs) {
        final event = CalendarEvent.fromFirestore(doc);
        mergedEvents[event.id] = event;
      }

      if (userId != null) {
        final createdBySnapshot = await eventsCollection
            .where('createdBy', isEqualTo: userId)
            .get();

        for (final doc in createdBySnapshot.docs) {
          final event = CalendarEvent.fromFirestore(doc);
          mergedEvents[event.id] = event;
        }
      }

      if (mergedEvents.isEmpty) {
        final allEventsSnapshot =
            await eventsCollection.orderBy('date', descending: false).get();

        for (final doc in allEventsSnapshot.docs) {
          final data = doc.data();
          final docFamilyId = (data['familyId'] as String? ?? '').trim();
          final createdBy = (data['createdBy'] as String? ?? '').trim();
          final createdByEmail =
              (data['createdByEmail'] as String? ?? '').trim().toLowerCase();
          final ownerEmail =
              (data['ownerEmail'] as String? ?? '').trim().toLowerCase();
          final email = (data['email'] as String? ?? '').trim().toLowerCase();

          final belongsToUser = (userId != null && createdBy == userId) ||
              (userEmail != null &&
                  {
                    createdByEmail,
                    ownerEmail,
                    email,
                  }.contains(userEmail.trim().toLowerCase()));

          if (docFamilyId == familyId || belongsToUser) {
            final event = CalendarEvent.fromFirestore(doc);
            mergedEvents[event.id] = event;
          }
        }
      }

      _events = mergedEvents.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEvent({
    required String familyId,
    required String title,
    required DateTime date,
    DateTime? endDate,
    required String categoryId,
    required String createdBy,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? notes,
    String? assignedToUserId,
    List<String> attendeeIds = const [],
    RecurrenceType recurrence = RecurrenceType.none,
    DateTime? recurrenceEndDate,
    List<int> recurrenceWeekdays = const [],
    bool allDay = false,
    String? iconAssetPath,
  }) async {
    try {
      final newEvent = CalendarEvent(
        id: _firestore.collection('events').doc().id,
        familyId: familyId,
        title: title,
        description: description,
        date: date,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        categoryId: categoryId,
        location: location,
        notes: notes,
        assignedToUserId: assignedToUserId,
        attendeeIds: attendeeIds,
        recurrence: recurrence,
        recurrenceEndDate: recurrenceEndDate,
        recurrenceWeekdays: recurrenceWeekdays,
        allDay: allDay,
        iconAssetPath: iconAssetPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: createdBy,
      );

      await _firestore
          .collection('events')
          .doc(newEvent.id)
          .set(newEvent.toFirestore());

      _events.add(newEvent);
      _events.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateEvent({
    required String eventId,
    String? title,
    DateTime? date,
    DateTime? endDate,
    String? categoryId,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? notes,
    String? assignedToUserId,
    List<String>? attendeeIds,
    RecurrenceType? recurrence,
    DateTime? recurrenceEndDate,
    List<int>? recurrenceWeekdays,
    bool? allDay,
    String? iconAssetPath,
  }) async {
    try {
      final index = _events.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        final updated = _events[index].copyWith(
          title: title,
          date: date,
          endDate: endDate,
          categoryId: categoryId,
          description: description,
          startTime: startTime,
          endTime: endTime,
          location: location,
          notes: notes,
          assignedToUserId: assignedToUserId,
          attendeeIds: attendeeIds,
          recurrence: recurrence,
          recurrenceEndDate: recurrenceEndDate,
          recurrenceWeekdays: recurrenceWeekdays,
          allDay: allDay,
          iconAssetPath: iconAssetPath,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('events')
            .doc(eventId)
            .update(updated.toFirestore());

        _events[index] = updated;
        _events.sort((a, b) => a.date.compareTo(b.date));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      _events.removeWhere((event) => event.id == eventId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> duplicateEvent(CalendarEvent event) async {
    try {
      final newEvent = CalendarEvent(
        id: _firestore.collection('events').doc().id,
        familyId: event.familyId,
        title: event.title,
        description: event.description,
        date: event.date.add(Duration(days: 1)),
        endDate: event.endDate?.add(Duration(days: 1)),
        startTime: event.startTime,
        endTime: event.endTime,
        categoryId: event.categoryId,
        location: event.location,
        notes: event.notes,
        assignedToUserId: event.assignedToUserId,
        attendeeIds: event.attendeeIds,
        allDay: event.allDay,
        iconAssetPath: event.iconAssetPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: event.createdBy,
      );

      await _firestore
          .collection('events')
          .doc(newEvent.id)
          .set(newEvent.toFirestore());

      _events.add(newEvent);
      _events.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    return _events.where((event) => event.occursOnDate(target)).toList()
      ..sort((a, b) {
        final aDate = a.firstOccurrenceInRange(target, target) ?? a.date;
        final bDate = b.firstOccurrenceInRange(target, target) ?? b.date;
        return aDate.compareTo(bDate);
      });
  }

  List<CalendarEvent> getEventsForMonth(DateTime date) {
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0);
    return _events
        .where((event) => event.overlapsRange(monthStart, monthEnd))
        .toList()
      ..sort((a, b) {
        final aDate = a.firstOccurrenceInRange(monthStart, monthEnd) ?? a.date;
        final bDate = b.firstOccurrenceInRange(monthStart, monthEnd) ?? b.date;
        return aDate.compareTo(bDate);
      });
  }

  List<CalendarEvent> getEventsForRange(DateTime start, DateTime end) {
    return _events
        .where((event) => event.overlapsRange(start, end))
        .toList()
      ..sort((a, b) {
        final aDate = a.firstOccurrenceInRange(start, end) ?? a.date;
        final bDate = b.firstOccurrenceInRange(start, end) ?? b.date;
        return aDate.compareTo(bDate);
      });
  }

  List<CalendarEvent> getUpcomingEvents({DateTime? from}) {
    final baseline = from ?? DateTime.now();
    final today = DateTime(baseline.year, baseline.month, baseline.day);
    return _events
        .where((event) => event.nextOccurrenceOnOrAfter(today) != null)
        .toList()
      ..sort((a, b) {
        final aDate = a.nextOccurrenceOnOrAfter(today) ?? a.date;
        final bDate = b.nextOccurrenceOnOrAfter(today) ?? b.date;
        return aDate.compareTo(bDate);
      });
  }

  CalendarEvent? getEventById(String id) {
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }
}
