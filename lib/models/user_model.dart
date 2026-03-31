import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  final bool notifyOnNewFamilyList;
  final bool notifyOnNewFamilyTask;
  final bool notifyOnTaskAssignedToMe;
  final bool notifyDailyMorningSummary;
  final int dailySummaryHour;
  final int dailySummaryMinute;

  const NotificationPreferences({
    this.notifyOnNewFamilyList = false,
    this.notifyOnNewFamilyTask = false,
    this.notifyOnTaskAssignedToMe = false,
    this.notifyDailyMorningSummary = false,
    this.dailySummaryHour = 8,
    this.dailySummaryMinute = 0,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic>? data) {
    return NotificationPreferences(
      notifyOnNewFamilyList: data?['notifyOnNewFamilyList'] == true,
      notifyOnNewFamilyTask: data?['notifyOnNewFamilyTask'] == true,
      notifyOnTaskAssignedToMe: data?['notifyOnTaskAssignedToMe'] == true,
      notifyDailyMorningSummary: data?['notifyDailyMorningSummary'] == true,
      dailySummaryHour: (data?['dailySummaryHour'] as num?)?.toInt() ?? 8,
      dailySummaryMinute: (data?['dailySummaryMinute'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifyOnNewFamilyList': notifyOnNewFamilyList,
      'notifyOnNewFamilyTask': notifyOnNewFamilyTask,
      'notifyOnTaskAssignedToMe': notifyOnTaskAssignedToMe,
      'notifyDailyMorningSummary': notifyDailyMorningSummary,
      'dailySummaryHour': dailySummaryHour,
      'dailySummaryMinute': dailySummaryMinute,
    };
  }

  NotificationPreferences copyWith({
    bool? notifyOnNewFamilyList,
    bool? notifyOnNewFamilyTask,
    bool? notifyOnTaskAssignedToMe,
    bool? notifyDailyMorningSummary,
    int? dailySummaryHour,
    int? dailySummaryMinute,
  }) {
    return NotificationPreferences(
      notifyOnNewFamilyList:
          notifyOnNewFamilyList ?? this.notifyOnNewFamilyList,
      notifyOnNewFamilyTask:
          notifyOnNewFamilyTask ?? this.notifyOnNewFamilyTask,
      notifyOnTaskAssignedToMe:
          notifyOnTaskAssignedToMe ?? this.notifyOnTaskAssignedToMe,
      notifyDailyMorningSummary:
          notifyDailyMorningSummary ?? this.notifyDailyMorningSummary,
      dailySummaryHour: dailySummaryHour ?? this.dailySummaryHour,
      dailySummaryMinute: dailySummaryMinute ?? this.dailySummaryMinute,
    );
  }

  @override
  List<Object?> get props => [
        notifyOnNewFamilyList,
        notifyOnNewFamilyTask,
        notifyOnTaskAssignedToMe,
        notifyDailyMorningSummary,
        dailySummaryHour,
        dailySummaryMinute,
      ];
}

class User extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String themeId;
  final String languageCode;
  final String role; // 'admin' or 'member'
  final String? familyId;
  final NotificationPreferences notificationPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.themeId = 'current_default',
    this.languageCode = 'en',
    this.role = 'member',
    this.familyId,
    this.notificationPreferences = const NotificationPreferences(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      themeId: data['themeId'] ?? 'current_default',
      languageCode: data['languageCode'] ?? 'en',
      role: data['role'] ?? 'member',
      familyId: data['familyId'],
      notificationPreferences: NotificationPreferences.fromMap(
        data['notificationPreferences'] as Map<String, dynamic>?,
      ),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'themeId': themeId,
      'languageCode': languageCode,
      'role': role,
      'familyId': familyId,
      'notificationPreferences': notificationPreferences.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? themeId,
    String? languageCode,
    String? role,
    String? familyId,
    NotificationPreferences? notificationPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      themeId: themeId ?? this.themeId,
      languageCode: languageCode ?? this.languageCode,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        themeId,
        languageCode,
        role,
        familyId,
        notificationPreferences,
        createdAt,
        updatedAt,
      ];
}
