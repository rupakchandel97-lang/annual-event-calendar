import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Family extends Equatable {
  final String id;
  final String name;
  final String adminId;
  final List<String> memberIds;
  final List<String> pendingInvites;
  final List<String> shoppingPlaces;
  final String? description;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Family({
    required this.id,
    required this.name,
    required this.adminId,
    this.memberIds = const [],
    this.pendingInvites = const [],
    this.shoppingPlaces = const [],
    this.description,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Family.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Family(
      id: doc.id,
      name: data['name'] ?? '',
      adminId: data['adminId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      pendingInvites: List<String>.from(data['pendingInvites'] ?? []),
      shoppingPlaces: List<String>.from(data['shoppingPlaces'] ?? []),
      description: data['description'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'adminId': adminId,
      'memberIds': memberIds,
      'pendingInvites': pendingInvites,
      'shoppingPlaces': shoppingPlaces,
      'description': description,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Family copyWith({
    String? id,
    String? name,
    String? adminId,
    List<String>? memberIds,
    List<String>? pendingInvites,
    List<String>? shoppingPlaces,
    String? description,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      pendingInvites: pendingInvites ?? this.pendingInvites,
      shoppingPlaces: shoppingPlaces ?? this.shoppingPlaces,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        adminId,
        memberIds,
        pendingInvites,
        shoppingPlaces,
        description,
        photoUrl,
        createdAt,
        updatedAt,
      ];
}
