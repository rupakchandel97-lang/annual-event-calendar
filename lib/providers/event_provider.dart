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

  Future<void> loadEvents(String familyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('events')
          .where('familyId', isEqualTo: familyId)
          .orderBy('date', descending: false)
          .get();

      _events = snapshot.docs
          .map((doc) => CalendarEvent.fromFirestore(doc))
          .toList();
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
    required String categoryId,
    required String createdBy,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? notes,
    String? assignedToUserId,
    List<String> attendeeIds = const [],
    bool allDay = false,
  }) async {
    try {
      final newEvent = CalendarEvent(
        id: _firestore.collection('events').doc().id,
        familyId: familyId,
        title: title,
        description: description,
        date: date,
        startTime: startTime,
        endTime: endTime,
        categoryId: categoryId,
        location: location,
        notes: notes,
        assignedToUserId: assignedToUserId,
        attendeeIds: attendeeIds,
        allDay: allDay,
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
    String? categoryId,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? notes,
    String? assignedToUserId,
    List<String>? attendeeIds,
    bool? allDay,
  }) async {
    try {
      final index = _events.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        final updated = _events[index].copyWith(
          title: title,
          date: date,
          categoryId: categoryId,
          description: description,
          startTime: startTime,
          endTime: endTime,
          location: location,
          notes: notes,
          assignedToUserId: assignedToUserId,
          attendeeIds: attendeeIds,
          allDay: allDay,
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
        startTime: event.startTime,
        endTime: event.endTime,
        categoryId: event.categoryId,
        location: event.location,
        notes: event.notes,
        assignedToUserId: event.assignedToUserId,
        attendeeIds: event.attendeeIds,
        allDay: event.allDay,
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
    return _events
        .where((event) =>
            event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day)
        .toList();
  }

  List<CalendarEvent> getEventsForMonth(DateTime date) {
    return _events
        .where((event) =>
            event.date.year == date.year &&
            event.date.month == date.month)
        .toList();
  }

  CalendarEvent? getEventById(String id) {
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }
}
