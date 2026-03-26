import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TodoListVisibility { private, shared }

TodoListVisibility todoListVisibilityFromString(String? value) {
  switch (value) {
    case 'shared':
      return TodoListVisibility.shared;
    case 'private':
    default:
      return TodoListVisibility.private;
  }
}

class TodoList extends Equatable {
  final String id;
  final String title;
  final String? description;
  final TodoListVisibility visibility;
  final String ownerUserId;
  final String? familyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoList({
    required this.id,
    required this.title,
    this.description,
    required this.visibility,
    required this.ownerUserId,
    this.familyId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPrivate => visibility == TodoListVisibility.private;
  bool get isShared => visibility == TodoListVisibility.shared;

  factory TodoList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoList(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      visibility: todoListVisibilityFromString(data['visibility']),
      ownerUserId: data['ownerUserId'] ?? '',
      familyId: data['familyId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'visibility': visibility.name,
      'ownerUserId': ownerUserId,
      'familyId': familyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TodoList copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    TodoListVisibility? visibility,
    String? ownerUserId,
    String? familyId,
    bool clearFamilyId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      visibility: visibility ?? this.visibility,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      familyId: clearFamilyId ? null : (familyId ?? this.familyId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        visibility,
        ownerUserId,
        familyId,
        createdAt,
        updatedAt,
      ];
}
