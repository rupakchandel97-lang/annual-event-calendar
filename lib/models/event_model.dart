import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RecurrenceType { none, daily, weekly, monthly, yearly }

class CalendarEvent extends Equatable {
  final String id;
  final String familyId;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String categoryId;
  final String? location;
  final String? notes;
  final String? assignedToUserId;
  final List<String> attendeeIds;
  final RecurrenceType recurrence;
  final DateTime? recurrenceEndDate;
  final bool allDay;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const CalendarEvent({
    required this.id,
    required this.familyId,
    required this.title,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    required this.categoryId,
    this.location,
    this.notes,
    this.assignedToUserId,
    this.attendeeIds = const [],
    this.recurrence = RecurrenceType.none,
    this.recurrenceEndDate,
    this.allDay = false,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      categoryId: data['categoryId'] ?? '',
      location: data['location'],
      notes: data['notes'],
      assignedToUserId: data['assignedToUserId'],
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.toString() == 'RecurrenceType.${data['recurrence'] ?? 'none'}',
        orElse: () => RecurrenceType.none,
      ),
      recurrenceEndDate: (data['recurrenceEndDate'] as Timestamp?)?.toDate(),
      allDay: data['allDay'] ?? false,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'categoryId': categoryId,
      'location': location,
      'notes': notes,
      'assignedToUserId': assignedToUserId,
      'attendeeIds': attendeeIds,
      'recurrence': recurrence.toString().split('.').last,
      'recurrenceEndDate': recurrenceEndDate != null
          ? Timestamp.fromDate(recurrenceEndDate!)
          : null,
      'allDay': allDay,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? familyId,
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? categoryId,
    String? location,
    String? notes,
    String? assignedToUserId,
    List<String>? attendeeIds,
    RecurrenceType? recurrence,
    DateTime? recurrenceEndDate,
    bool? allDay,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      categoryId: categoryId ?? this.categoryId,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      allDay: allDay ?? this.allDay,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        title,
        description,
        date,
        startTime,
        endTime,
        categoryId,
        location,
        notes,
        assignedToUserId,
        attendeeIds,
        recurrence,
        recurrenceEndDate,
        allDay,
        imageUrl,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
