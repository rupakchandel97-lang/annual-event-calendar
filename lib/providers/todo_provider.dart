import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/todo_list_model.dart';
import '../models/todo_task_model.dart';
import '../utils/constants.dart';

enum TodoTaskSortOption { dueDate, assignee, priority }

class TodoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _privateListsSubscription;
  StreamSubscription<QuerySnapshot>? _sharedListsSubscription;
  StreamSubscription<QuerySnapshot>? _privateTasksSubscription;
  StreamSubscription<QuerySnapshot>? _sharedTasksSubscription;

  String? _userId;
  String? _familyId;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, TodoList> _privateLists = {};
  Map<String, TodoList> _sharedLists = {};
  Map<String, TodoTask> _privateTasks = {};
  Map<String, TodoTask> _sharedTasks = {};
  bool _notifyScheduled = false;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TodoList> get privateLists => _sortLists(_privateLists.values);
  List<TodoList> get sharedLists => _sortLists(_sharedLists.values);

  void syncSession({
    required String? userId,
    required String? familyId,
  }) {
    final userChanged = userId != _userId;
    final familyChanged = familyId != _familyId;

    if (!userChanged && !familyChanged) {
      return;
    }

    _userId = userId;
    _familyId = familyId;

    if (_userId == null) {
      clear();
      return;
    }

    _startListening();
  }

  void clear() {
    _cancelSubscriptions();
    _userId = null;
    _familyId = null;
    _privateLists = {};
    _sharedLists = {};
    _privateTasks = {};
    _sharedTasks = {};
    _isLoading = false;
    _errorMessage = null;
    _notifySafely();
  }

  Future<void> createList({
    required String title,
    String? description,
    required TodoListVisibility visibility,
  }) async {
    if (_userId == null) {
      return;
    }

    if (visibility == TodoListVisibility.shared && _familyId == null) {
      _errorMessage = 'Join a family before creating a shared list.';
      _notifySafely();
      return;
    }

    try {
      final doc = _firestore.collection(AppConstants.todoListsCollection).doc();
      final list = TodoList(
        id: doc.id,
        title: title.trim(),
        description: _nullableTrim(description),
        visibility: visibility,
        ownerUserId: _userId!,
        familyId:
            visibility == TodoListVisibility.shared ? _familyId : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await doc.set(list.toFirestore());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> updateList({
    required TodoList list,
    required String title,
    String? description,
  }) async {
    try {
      final normalizedDescription = _nullableTrim(description);
      final updated = list.copyWith(
        title: title.trim(),
        description: normalizedDescription,
        clearDescription: normalizedDescription == null,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.todoListsCollection)
          .doc(list.id)
          .update(updated.toFirestore());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> deleteList(TodoList list) async {
    try {
      final batch = _firestore.batch();
      final tasks = await _firestore
          .collection(AppConstants.todoTasksCollection)
          .where('listId', isEqualTo: list.id)
          .get();

      for (final doc in tasks.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(
        _firestore.collection(AppConstants.todoListsCollection).doc(list.id),
      );
      await batch.commit();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> createTask({
    required TodoList list,
    required String title,
    String? notes,
    DateTime? dueDate,
    List<String> assigneeIds = const [],
    TodoTaskStatus status = TodoTaskStatus.todo,
    TodoTaskPriority priority = TodoTaskPriority.medium,
  }) async {
    if (_userId == null) {
      return;
    }

    try {
      final doc = _firestore.collection(AppConstants.todoTasksCollection).doc();
      final normalizedAssignees = list.isPrivate
          ? <String>[]
          : assigneeIds.where((id) => id.trim().isNotEmpty).toSet().toList();

      final task = TodoTask(
        id: doc.id,
        listId: list.id,
        title: title.trim(),
        notes: _nullableTrim(notes),
        dueDate: dueDate == null
            ? null
            : DateTime(dueDate.year, dueDate.month, dueDate.day),
        assigneeIds: normalizedAssignees,
        status: status,
        priority: priority,
        visibility: list.visibility,
        ownerUserId: list.ownerUserId,
        familyId: list.familyId,
        createdBy: _userId!,
        completedAt:
            status == TodoTaskStatus.completed ? DateTime.now() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await doc.set(task.toFirestore());
      await _touchList(list.id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> updateTask({
    required TodoTask task,
    required String title,
    String? notes,
    DateTime? dueDate,
    List<String>? assigneeIds,
    required TodoTaskStatus status,
    required TodoTaskPriority priority,
  }) async {
    try {
      final normalizedNotes = _nullableTrim(notes);
      final normalizedAssignees = task.visibility == TodoListVisibility.private
          ? <String>[]
          : (assigneeIds ?? task.assigneeIds)
              .where((id) => id.trim().isNotEmpty)
              .toSet()
              .toList();

      final updated = task.copyWith(
        title: title.trim(),
        notes: normalizedNotes,
        clearNotes: normalizedNotes == null,
        dueDate: dueDate == null
            ? null
            : DateTime(dueDate.year, dueDate.month, dueDate.day),
        clearDueDate: dueDate == null,
        assigneeIds: normalizedAssignees,
        status: status,
        priority: priority,
        completedAt:
            status == TodoTaskStatus.completed ? DateTime.now() : null,
        clearCompletedAt: status != TodoTaskStatus.completed,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.todoTasksCollection)
          .doc(task.id)
          .update(updated.toFirestore());

      await _touchList(task.listId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> updateTaskStatus({
    required TodoTask task,
    required TodoTaskStatus status,
  }) async {
    await updateTask(
      task: task,
      title: task.title,
      notes: task.notes,
      dueDate: task.dueDate,
      assigneeIds: task.assigneeIds,
      status: status,
      priority: task.priority,
    );
  }

  Future<void> deleteTask(TodoTask task) async {
    try {
      await _firestore
          .collection(AppConstants.todoTasksCollection)
          .doc(task.id)
          .delete();
      await _touchList(task.listId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  int incompleteCountForList(String listId) {
    return _allTasks
        .where((task) => task.listId == listId && !task.isCompleted)
        .length;
  }

  List<TodoTask> tasksForList(
    String listId, {
    TodoTaskSortOption sortBy = TodoTaskSortOption.dueDate,
    bool includeCompleted = false,
  }) {
    final tasks = _allTasks.where((task) => task.listId == listId).toList();

    final visibleTasks = includeCompleted
        ? tasks
        : tasks.where((task) => !task.isCompleted).toList();

    visibleTasks.sort((a, b) {
      final completionCompare =
          (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0);
      if (completionCompare != 0) {
        return completionCompare;
      }

      final sortCompare = switch (sortBy) {
        TodoTaskSortOption.priority => _comparePriority(a, b),
        TodoTaskSortOption.assignee => _compareAssignees(a, b),
        TodoTaskSortOption.dueDate => _compareDueDate(a, b),
      };

      if (sortCompare != 0) {
        return sortCompare;
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    return visibleTasks;
  }

  List<TodoTask> get _allTasks => [
        ..._privateTasks.values,
        ..._sharedTasks.values,
      ];

  void _startListening() {
    _cancelSubscriptions();
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    _privateListsSubscription = _firestore
        .collection(AppConstants.todoListsCollection)
        .where('ownerUserId', isEqualTo: _userId)
        .snapshots()
        .listen(
      (snapshot) {
        final items = <String, TodoList>{};
        for (final doc in snapshot.docs) {
          final list = TodoList.fromFirestore(doc);
          if (list.isPrivate) {
            items[doc.id] = list;
          }
        }
        _privateLists = items;
        _markLoaded();
      },
      onError: _handleStreamError,
    );

    _privateTasksSubscription = _firestore
        .collection(AppConstants.todoTasksCollection)
        .where('ownerUserId', isEqualTo: _userId)
        .snapshots()
        .listen(
      (snapshot) {
        final items = <String, TodoTask>{};
        for (final doc in snapshot.docs) {
          final task = TodoTask.fromFirestore(doc);
          if (task.visibility == TodoListVisibility.private) {
            items[doc.id] = task;
          }
        }
        _privateTasks = items;
        _markLoaded();
      },
      onError: _handleStreamError,
    );

    if (_familyId == null) {
      _sharedLists = {};
      _sharedTasks = {};
      _markLoaded();
      return;
    }

    _sharedListsSubscription = _firestore
        .collection(AppConstants.todoListsCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen(
      (snapshot) {
        final items = <String, TodoList>{};
        for (final doc in snapshot.docs) {
          final list = TodoList.fromFirestore(doc);
          if (list.isShared) {
            items[doc.id] = list;
          }
        }
        _sharedLists = items;
        _markLoaded();
      },
      onError: _handleStreamError,
    );

    _sharedTasksSubscription = _firestore
        .collection(AppConstants.todoTasksCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen(
      (snapshot) {
        final items = <String, TodoTask>{};
        for (final doc in snapshot.docs) {
          final task = TodoTask.fromFirestore(doc);
          if (task.visibility == TodoListVisibility.shared) {
            items[doc.id] = task;
          }
        }
        _sharedTasks = items;
        _markLoaded();
      },
      onError: _handleStreamError,
    );
  }

  void _markLoaded() {
    _isLoading = false;
    _notifySafely();
  }

  void _handleStreamError(Object error) {
    _isLoading = false;
    _errorMessage = error.toString();
    _notifySafely();
  }

  void _notifySafely() {
    if (_disposed || _notifyScheduled) {
      return;
    }

    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) {
        _notifyScheduled = false;
        return;
      }
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  Future<void> _touchList(String listId) async {
    await _firestore
        .collection(AppConstants.todoListsCollection)
        .doc(listId)
        .update({
      'updatedAt': Timestamp.now(),
    });
  }

  List<TodoList> _sortLists(Iterable<TodoList> lists) {
    final sorted = lists.toList()
      ..sort((a, b) {
        final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return sorted;
  }

  int _compareDueDate(TodoTask a, TodoTask b) {
    if (a.dueDate == null && b.dueDate == null) {
      return 0;
    }
    if (a.dueDate == null) {
      return 1;
    }
    if (b.dueDate == null) {
      return -1;
    }
    return a.dueDate!.compareTo(b.dueDate!);
  }

  int _comparePriority(TodoTask a, TodoTask b) {
    final weight = <TodoTaskPriority, int>{
      TodoTaskPriority.high: 0,
      TodoTaskPriority.medium: 1,
      TodoTaskPriority.low: 2,
    };
    return (weight[a.priority] ?? 99).compareTo(weight[b.priority] ?? 99);
  }

  int _compareAssignees(TodoTask a, TodoTask b) {
    final aKey = a.assigneeIds.isEmpty ? 'zzzz' : a.assigneeIds.first;
    final bKey = b.assigneeIds.isEmpty ? 'zzzz' : b.assigneeIds.first;
    return aKey.compareTo(bKey);
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void _cancelSubscriptions() {
    _privateListsSubscription?.cancel();
    _sharedListsSubscription?.cancel();
    _privateTasksSubscription?.cancel();
    _sharedTasksSubscription?.cancel();
    _privateListsSubscription = null;
    _sharedListsSubscription = null;
    _privateTasksSubscription = null;
    _sharedTasksSubscription = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSubscriptions();
    super.dispose();
  }
}
