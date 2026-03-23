import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String themeId;
  final String role; // 'admin' or 'member'
  final String? familyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.themeId = 'current_default',
    this.role = 'member',
    this.familyId,
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
      role: data['role'] ?? 'member',
      familyId: data['familyId'],
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
      'role': role,
      'familyId': familyId,
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
    String? role,
    String? familyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      themeId: themeId ?? this.themeId,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
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
        role,
        familyId,
        createdAt,
        updatedAt,
      ];
}
