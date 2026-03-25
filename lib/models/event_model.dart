import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RecurrenceType { none, daily, weekly, monthly, yearly }

const Object _unset = Object();

class CalendarEvent extends Equatable {
  final String id;
  final String familyId;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? endDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String categoryId;
  final String? location;
  final String? notes;
  final String? assignedToUserId;
  final List<String> attendeeIds;
  final RecurrenceType recurrence;
  final DateTime? recurrenceEndDate;
  final List<int> recurrenceWeekdays;
  final bool allDay;
  final String? iconAssetPath;
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
    this.endDate,
    this.startTime,
    this.endTime,
    required this.categoryId,
    this.location,
    this.notes,
    this.assignedToUserId,
    this.attendeeIds = const [],
    this.recurrence = RecurrenceType.none,
    this.recurrenceEndDate,
    this.recurrenceWeekdays = const [],
    this.allDay = false,
    this.iconAssetPath,
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
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
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
      recurrenceWeekdays: List<int>.from(data['recurrenceWeekdays'] ?? const []),
      allDay: data['allDay'] ?? false,
      iconAssetPath: data['iconAssetPath'],
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
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
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
      'recurrenceWeekdays': recurrenceWeekdays,
      'allDay': allDay,
      'iconAssetPath': iconAssetPath,
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
    Object? description = _unset,
    DateTime? date,
    Object? endDate = _unset,
    Object? startTime = _unset,
    Object? endTime = _unset,
    String? categoryId,
    Object? location = _unset,
    Object? notes = _unset,
    Object? assignedToUserId = _unset,
    List<String>? attendeeIds,
    RecurrenceType? recurrence,
    Object? recurrenceEndDate = _unset,
    List<int>? recurrenceWeekdays,
    bool? allDay,
    Object? iconAssetPath = _unset,
    Object? imageUrl = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      date: date ?? this.date,
      endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
      startTime: identical(startTime, _unset)
          ? this.startTime
          : startTime as DateTime?,
      endTime: identical(endTime, _unset) ? this.endTime : endTime as DateTime?,
      categoryId: categoryId ?? this.categoryId,
      location: identical(location, _unset) ? this.location : location as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      assignedToUserId: identical(assignedToUserId, _unset)
          ? this.assignedToUserId
          : assignedToUserId as String?,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate: identical(recurrenceEndDate, _unset)
          ? this.recurrenceEndDate
          : recurrenceEndDate as DateTime?,
      recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
      allDay: allDay ?? this.allDay,
      iconAssetPath: identical(iconAssetPath, _unset)
          ? this.iconAssetPath
          : iconAssetPath as String?,
      imageUrl: identical(imageUrl, _unset) ? this.imageUrl : imageUrl as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  DateTime get startDateOnly => DateTime(date.year, date.month, date.day);
  DateTime? get recurrenceEndDateOnly => recurrenceEndDate == null
      ? null
      : DateTime(
          recurrenceEndDate!.year,
          recurrenceEndDate!.month,
          recurrenceEndDate!.day,
        );

  DateTime get endDateOnly {
    final lastDate = endDate ?? date;
    return DateTime(lastDate.year, lastDate.month, lastDate.day);
  }

  bool get isMultiDay => endDateOnly.isAfter(startDateOnly);
  bool get isRecurring => recurrence != RecurrenceType.none;
  int get durationInDays => endDateOnly.difference(startDateOnly).inDays;

  List<int> get effectiveRecurrenceWeekdays {
    if (recurrence != RecurrenceType.weekly) {
      return const [];
    }

    final weekdays = recurrenceWeekdays.isEmpty
        ? <int>[startDateOnly.weekday]
        : recurrenceWeekdays;

    final uniqueWeekdays = weekdays.toSet().toList()..sort();
    return uniqueWeekdays;
  }

  bool occursOnDate(DateTime targetDate) {
    final day = DateTime(targetDate.year, targetDate.month, targetDate.day);
    if (!isRecurring) {
      return !day.isBefore(startDateOnly) && !day.isAfter(endDateOnly);
    }

    if (day.isBefore(startDateOnly)) {
      return false;
    }

    // Weekly recurrence with explicitly selected weekdays should only appear
    // on those weekdays, rather than bleeding across adjacent days.
    if (recurrence == RecurrenceType.weekly &&
        effectiveRecurrenceWeekdays.length > 1) {
      return _isOccurrenceStartOn(day);
    }

    for (var offset = 0; offset <= durationInDays; offset++) {
      final candidateStart = day.subtract(Duration(days: offset));
      if (_isOccurrenceStartOn(candidateStart)) {
        return true;
      }
    }

    return false;
  }

  bool overlapsRange(DateTime rangeStart, DateTime rangeEnd) {
    final normalizedStart = DateTime(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );
    final normalizedEnd = DateTime(
      rangeEnd.year,
      rangeEnd.month,
      rangeEnd.day,
    );

    if (isRecurring) {
      var cursor = normalizedStart;
      while (!cursor.isAfter(normalizedEnd)) {
        if (occursOnDate(cursor)) {
          return true;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      return false;
    }

    return !endDateOnly.isBefore(normalizedStart) &&
        !startDateOnly.isAfter(normalizedEnd);
  }

  DateTime? nextOccurrenceOnOrAfter(DateTime from) {
    final normalizedFrom = DateTime(from.year, from.month, from.day);

    if (!isRecurring) {
      if (endDateOnly.isBefore(normalizedFrom)) {
        return null;
      }
      if (!startDateOnly.isAfter(normalizedFrom)) {
        return normalizedFrom;
      }
      return startDateOnly;
    }

    if (occursOnDate(normalizedFrom)) {
      return normalizedFrom;
    }

    switch (recurrence) {
      case RecurrenceType.none:
        return null;
      case RecurrenceType.daily:
        final nextDay =
            normalizedFrom.isAfter(startDateOnly) ? normalizedFrom : startDateOnly;
        return _isOccurrenceStartOn(nextDay) ? nextDay : null;
      case RecurrenceType.weekly:
        final baseline =
            normalizedFrom.isAfter(startDateOnly) ? normalizedFrom : startDateOnly;
        for (var offset = 0; offset < 7; offset++) {
          final candidate = baseline.add(Duration(days: offset));
          if (_isOccurrenceStartOn(candidate)) {
            return candidate;
          }
        }
        return null;
      case RecurrenceType.monthly:
        var candidateMonth = DateTime(
          normalizedFrom.year,
          normalizedFrom.month,
          startDateOnly.day,
        );
        if (candidateMonth.day != startDateOnly.day ||
            candidateMonth.isBefore(startDateOnly) ||
            candidateMonth.isBefore(normalizedFrom)) {
          candidateMonth = DateTime(
            normalizedFrom.year,
            normalizedFrom.month + 1,
            startDateOnly.day,
          );
        }
        for (var attempt = 0; attempt < 24; attempt++) {
          if (_isOccurrenceStartOn(candidateMonth)) {
            return candidateMonth;
          }
          candidateMonth = DateTime(
            candidateMonth.year,
            candidateMonth.month + 1,
            startDateOnly.day,
          );
        }
        return null;
      case RecurrenceType.yearly:
        var candidateYear = DateTime(
          normalizedFrom.year,
          startDateOnly.month,
          startDateOnly.day,
        );
        if (candidateYear.month != startDateOnly.month ||
            candidateYear.day != startDateOnly.day ||
            candidateYear.isBefore(startDateOnly) ||
            candidateYear.isBefore(normalizedFrom)) {
          candidateYear = DateTime(
            normalizedFrom.year + 1,
            startDateOnly.month,
            startDateOnly.day,
          );
        }
        for (var attempt = 0; attempt < 10; attempt++) {
          if (_isOccurrenceStartOn(candidateYear)) {
            return candidateYear;
          }
          candidateYear = DateTime(
            candidateYear.year + 1,
            startDateOnly.month,
            startDateOnly.day,
          );
        }
        return null;
    }
  }

  DateTime? firstOccurrenceInRange(DateTime rangeStart, DateTime rangeEnd) {
    final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    final nextOccurrence = nextOccurrenceOnOrAfter(start);
    if (nextOccurrence == null || nextOccurrence.isAfter(end)) {
      return null;
    }
    return nextOccurrence;
  }

  bool _isOccurrenceStartOn(DateTime candidate) {
    final day = DateTime(candidate.year, candidate.month, candidate.day);
    final recurrenceLimit = recurrenceEndDateOnly;

    if (day.isBefore(startDateOnly)) {
      return false;
    }

    if (recurrenceLimit != null && day.isAfter(recurrenceLimit)) {
      return false;
    }

    switch (recurrence) {
      case RecurrenceType.none:
        return day == startDateOnly;
      case RecurrenceType.daily:
        return true;
      case RecurrenceType.weekly:
        return effectiveRecurrenceWeekdays.contains(day.weekday);
      case RecurrenceType.monthly:
        return day.day == startDateOnly.day;
      case RecurrenceType.yearly:
        return day.month == startDateOnly.month && day.day == startDateOnly.day;
    }
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        title,
        description,
        date,
        endDate,
        startTime,
        endTime,
        categoryId,
        location,
        notes,
        assignedToUserId,
        attendeeIds,
        recurrence,
        recurrenceEndDate,
        recurrenceWeekdays,
        allDay,
        iconAssetPath,
        imageUrl,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
