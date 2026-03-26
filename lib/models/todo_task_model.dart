import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'todo_list_model.dart';

enum TodoTaskStatus { todo, inProgress, blocked, completed }

enum TodoTaskPriority { low, medium, high }

TodoTaskStatus todoTaskStatusFromString(String? value) {
  switch (value) {
    case 'inProgress':
      return TodoTaskStatus.inProgress;
    case 'blocked':
      return TodoTaskStatus.blocked;
    case 'completed':
      return TodoTaskStatus.completed;
    case 'todo':
    default:
      return TodoTaskStatus.todo;
  }
}

TodoTaskPriority todoTaskPriorityFromString(String? value) {
  switch (value) {
    case 'high':
      return TodoTaskPriority.high;
    case 'low':
      return TodoTaskPriority.low;
    case 'medium':
    default:
      return TodoTaskPriority.medium;
  }
}

class TodoTask extends Equatable {
  final String id;
  final String listId;
  final String title;
  final String? notes;
  final DateTime? dueDate;
  final List<String> assigneeIds;
  final TodoTaskStatus status;
  final TodoTaskPriority priority;
  final TodoListVisibility visibility;
  final String ownerUserId;
  final String? familyId;
  final String createdBy;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoTask({
    required this.id,
    required this.listId,
    required this.title,
    this.notes,
    this.dueDate,
    this.assigneeIds = const [],
    this.status = TodoTaskStatus.todo,
    this.priority = TodoTaskPriority.medium,
    required this.visibility,
    required this.ownerUserId,
    this.familyId,
    required this.createdBy,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == TodoTaskStatus.completed;

  factory TodoTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoTask(
      id: doc.id,
      listId: data['listId'] ?? '',
      title: data['title'] ?? '',
      notes: data['notes'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      assigneeIds: List<String>.from(data['assigneeIds'] ?? const []),
      status: todoTaskStatusFromString(data['status']),
      priority: todoTaskPriorityFromString(data['priority']),
      visibility: todoListVisibilityFromString(data['visibility']),
      ownerUserId: data['ownerUserId'] ?? '',
      familyId: data['familyId'],
      createdBy: data['createdBy'] ?? '',
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'title': title,
      'notes': notes,
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
      'assigneeIds': assigneeIds,
      'status': status.name,
      'priority': priority.name,
      'visibility': visibility.name,
      'ownerUserId': ownerUserId,
      'familyId': familyId,
      'createdBy': createdBy,
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TodoTask copyWith({
    String? id,
    String? listId,
    String? title,
    String? notes,
    bool clearNotes = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    List<String>? assigneeIds,
    TodoTaskStatus? status,
    TodoTaskPriority? priority,
    TodoListVisibility? visibility,
    String? ownerUserId,
    String? familyId,
    bool clearFamilyId = false,
    String? createdBy,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoTask(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      assigneeIds: assigneeIds ?? this.assigneeIds,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      visibility: visibility ?? this.visibility,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      familyId: clearFamilyId ? null : (familyId ?? this.familyId),
      createdBy: createdBy ?? this.createdBy,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        listId,
        title,
        notes,
        dueDate,
        assigneeIds,
        status,
        priority,
        visibility,
        ownerUserId,
        familyId,
        createdBy,
        completedAt,
        createdAt,
        updatedAt,
      ];
}
