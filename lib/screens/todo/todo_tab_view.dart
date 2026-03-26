import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/todo_list_model.dart';
import '../../models/todo_task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/todo_provider.dart';
import '../../theme/app_theme.dart';
import 'household_workspace_view.dart';

enum TodoLayoutMode { compact, detailed }
enum TodoWorkspaceSection { tasks, shopping }

class _TodoListDraft {
  final String title;
  final String description;

  const _TodoListDraft({
    required this.title,
    required this.description,
  });
}

class _TodoTaskDraft {
  final String title;
  final String notes;
  final DateTime? dueDate;
  final List<String> assigneeIds;
  final TodoTaskStatus status;
  final TodoTaskPriority priority;

  const _TodoTaskDraft({
    required this.title,
    required this.notes,
    required this.dueDate,
    required this.assigneeIds,
    required this.status,
    required this.priority,
  });
}

class _TodoListDialog extends StatefulWidget {
  final TodoList? existing;

  const _TodoListDialog({
    required this.existing,
  });

  @override
  State<_TodoListDialog> createState() => _TodoListDialogState();
}

class _TodoListDialogState extends State<_TodoListDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final strings = AppStrings.of(context);

    return AlertDialog(
      title: Text(widget.existing == null ? strings.createListTitle : strings.editListTitle),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 14.5),
              decoration: InputDecoration(
                labelText: 'List name',
                hintText: strings.listName,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                prefixIcon: const Icon(Icons.checklist_rtl_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: palette.vibrantOutline.withOpacity(0.4),
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return strings.enterListNamePrompt;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 1,
              maxLines: 3,
              style: const TextStyle(fontSize: 14.5),
              decoration: InputDecoration(
                labelText: strings.descriptionLabel,
                hintText: strings.descriptionLabel,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: palette.vibrantOutline.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              _TodoListDraft(
                title: _titleController.text,
                description: _descriptionController.text,
              ),
            );
          },
          child: Text(widget.existing == null ? strings.create : strings.save),
        ),
      ],
    );
  }
}

class _TodoTaskDialog extends StatefulWidget {
  final TodoList list;
  final List<User> familyMembers;
  final User? currentUser;
  final TodoTask? existing;
  final String Function(TodoTaskStatus status) taskStatusLabel;
  final String Function(TodoTaskPriority priority) priorityLabel;

  const _TodoTaskDialog({
    required this.list,
    required this.familyMembers,
    required this.currentUser,
    required this.existing,
    required this.taskStatusLabel,
    required this.priorityLabel,
  });

  @override
  State<_TodoTaskDialog> createState() => _TodoTaskDialogState();
}

class _TodoTaskDialogState extends State<_TodoTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  late DateTime? _selectedDate;
  late TodoTaskStatus _selectedStatus;
  late TodoTaskPriority _selectedPriority;
  late Set<String> _selectedAssignees;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _notesController = TextEditingController(text: widget.existing?.notes ?? '');
    _selectedDate = widget.existing?.dueDate;
    _selectedStatus = widget.existing?.status ?? TodoTaskStatus.todo;
    _selectedPriority =
        widget.existing?.priority ?? TodoTaskPriority.medium;
    _selectedAssignees = widget.existing?.assigneeIds.toSet() ?? <String>{};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final availableAssignees = widget.list.isPrivate
        ? (widget.currentUser == null ? const <User>[] : [widget.currentUser!])
        : widget.familyMembers;

    return AlertDialog(
      title: Text(widget.existing == null ? strings.addTaskTitle : strings.editTaskTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: strings.taskName,
                    hintText: strings.taskName,
                    prefixIcon: const Icon(Icons.task_alt_outlined),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return strings.enterTaskNamePrompt;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: strings.notesLabel,
                    hintText: strings.notesLabel,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(
                    _selectedDate == null
                        ? strings.noDueDate
                        : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      if (_selectedDate != null)
                        IconButton(
                          onPressed: () {
                            setState(() => _selectedDate = null);
                          },
                          icon: const Icon(Icons.clear_outlined),
                        ),
                      IconButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null && mounted) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.edit_calendar_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TodoTaskStatus>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: strings.statusLabel,
                    hintText: strings.statusLabel,
                    prefixIcon: const Icon(Icons.sync_alt_outlined),
                  ),
                  items: TodoTaskStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(widget.taskStatusLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TodoTaskPriority>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: strings.priorityLabelText,
                    hintText: strings.priorityLabelText,
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  items: TodoTaskPriority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(widget.priorityLabel(priority)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPriority = value);
                    }
                  },
                ),
                if (widget.list.isShared) ...[
                  const SizedBox(height: 16),
                  Text(
                    strings.assignToFamilyMembers,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableAssignees.map((member) {
                      final isSelected =
                          _selectedAssignees.contains(member.uid);
                      return FilterChip(
                        label: Text(member.displayName),
                        selected: isSelected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedAssignees.add(member.uid);
                            } else {
                              _selectedAssignees.remove(member.uid);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              _TodoTaskDraft(
                title: _titleController.text,
                notes: _notesController.text,
                dueDate: _selectedDate,
                assigneeIds: _selectedAssignees.toList(),
                status: _selectedStatus,
                priority: _selectedPriority,
              ),
            );
          },
          child: Text(widget.existing == null ? strings.create : strings.save),
        ),
      ],
    );
  }
}

List<User> _assigneesForTask(
  TodoTask task,
  List<User> familyMembers,
  User? currentUser,
) {
  if (task.visibility == TodoListVisibility.private) {
    return currentUser == null ? const [] : [currentUser];
  }

  return familyMembers
      .where((member) => task.assigneeIds.contains(member.uid))
      .toList();
}

TodoList? _findListById(
  Iterable<TodoList> lists,
  String listId,
) {
  for (final list in lists) {
    if (list.id == listId) {
      return list;
    }
  }

  return null;
}

void _openTaskEvent(BuildContext context, TodoTask task) {
  context.push(
    '/event/add',
    extra: {
      'title': task.title,
      'notes': task.notes,
    },
  );
}

class TodoTabView extends StatefulWidget {
  const TodoTabView({super.key});

  @override
  State<TodoTabView> createState() => _TodoTabViewState();
}

class _TodoTabViewState extends State<TodoTabView> {
  TodoWorkspaceSection _workspaceSection = TodoWorkspaceSection.tasks;
  TodoListVisibility _selectedVisibility = TodoListVisibility.private;
  TodoLayoutMode _layoutMode = TodoLayoutMode.compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Consumer3<TodoProvider, FamilyProvider, AuthProvider>(
      builder: (context, todoProvider, familyProvider, authProvider, _) {
        final palette = AppTheme.of(context);
        final currentUser = authProvider.currentUser;
        final hasFamily = currentUser?.familyId != null;

        final effectiveVisibility =
            !hasFamily && _selectedVisibility == TodoListVisibility.shared
                ? TodoListVisibility.private
                : _selectedVisibility;

        final lists = effectiveVisibility == TodoListVisibility.private
            ? todoProvider.privateLists
            : todoProvider.sharedLists;

        return Container(
          decoration: BoxDecoration(
            gradient: palette.pageGradient,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            palette.isDark ? 0.08 : 0.9,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: palette.vibrantOutline.withOpacity(0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                palette.isDark ? 0.16 : 0.05,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        palette.primary.withOpacity(
                                          palette.isDark ? 0.92 : 0.9,
                                        ),
                                        palette.secondary.withOpacity(
                                          palette.isDark ? 0.92 : 0.86,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    switch (_workspaceSection) {
                                      TodoWorkspaceSection.tasks =>
                                        Icons.fact_check_outlined,
                                      TodoWorkspaceSection.shopping =>
                                        Icons.shopping_cart_outlined,
                                    },
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        switch (_workspaceSection) {
                                          TodoWorkspaceSection.tasks =>
                                            effectiveVisibility ==
                                                    TodoListVisibility.private
                                                ? strings.myTaskLists
                                                : strings.familyTaskLists,
                                          TodoWorkspaceSection.shopping =>
                                            strings.shopping,
                                        },
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: palette.textPrimary,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        switch (_workspaceSection) {
                                          TodoWorkspaceSection.tasks =>
                                            strings.taskWorkspaceSubtitle,
                                          TodoWorkspaceSection.shopping =>
                                            strings.shoppingWorkspaceSubtitle,
                                        },
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: 13,
                                              color: palette.textMuted,
                                              height: 1.15,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_workspaceSection ==
                                        TodoWorkspaceSection.tasks ||
                                    _workspaceSection ==
                                        TodoWorkspaceSection.shopping)
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      if (_workspaceSection ==
                                          TodoWorkspaceSection.tasks) {
                                        _showListDialog(
                                          context: context,
                                          visibility: effectiveVisibility,
                                        );
                                      } else {
                                        showShoppingListEditor(context);
                                      }
                                    },
                                    icon:
                                        const Icon(Icons.playlist_add_outlined),
                                    label: Text(strings.newList),
                                    style: FilledButton.styleFrom(
                                      foregroundColor: palette.textPrimary,
                                      backgroundColor: palette.surfaceAlt
                                          .withOpacity(
                                            palette.isDark ? 0.42 : 0.9,
                                          ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SegmentGroupCard(
                              title: strings.workspace,
                              child: _CompactSegmentedButton<TodoWorkspaceSection>(
                                segments: [
                                  ButtonSegment<TodoWorkspaceSection>(
                                    value: TodoWorkspaceSection.tasks,
                                    icon: const Icon(Icons.task_alt_outlined),
                                    label: Text(strings.tasks),
                                  ),
                                  ButtonSegment<TodoWorkspaceSection>(
                                    value: TodoWorkspaceSection.shopping,
                                    icon: const Icon(Icons.shopping_cart_outlined),
                                    label: Text(strings.shopping),
                                  ),
                                ],
                                selected: {_workspaceSection},
                                onSelectionChanged: (value) {
                                  setState(() {
                                    _workspaceSection = value.first;
                                  });
                                },
                              ),
                            ),
                            if (_workspaceSection == TodoWorkspaceSection.tasks) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _SegmentGroupCard(
                                    title: strings.scope,
                                    child: _CompactSegmentedButton<TodoListVisibility>(
                                      segments: [
                                        ButtonSegment<TodoListVisibility>(
                                          value: TodoListVisibility.private,
                                          icon: const Icon(Icons.lock_outline),
                                          label: Text(strings.myLists),
                                        ),
                                        ButtonSegment<TodoListVisibility>(
                                          value: TodoListVisibility.shared,
                                          icon: const Icon(Icons.groups_outlined),
                                          label: const Text('Family Lists'),
                                          enabled: hasFamily,
                                        ),
                                      ],
                                      selected: {effectiveVisibility},
                                      onSelectionChanged: (value) {
                                        setState(() {
                                          _selectedVisibility = value.first;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_workspaceSection == TodoWorkspaceSection.shopping)
                  Expanded(child: ShoppingWorkspaceView(hasFamily: hasFamily))
                else ...[
                  if (todoProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        todoProvider.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.error,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (todoProvider.isLoading && lists.isEmpty)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (lists.isEmpty)
                    Expanded(
                      child: _EmptyTodoState(
                        visibility: effectiveVisibility,
                        hasFamily: hasFamily,
                        onCreatePressed: () => _showListDialog(
                          context: context,
                          visibility: effectiveVisibility,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: lists.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          color: palette.vibrantOutline.withOpacity(0.18),
                        ),
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          final totalTaskCount = todoProvider
                              .tasksForList(list.id, includeCompleted: true)
                              .length;
                          final openTaskCount = todoProvider.incompleteCountForList(
                            list.id,
                          );
                          return _TodoListLandingCard(
                            list: list,
                            openCount: openTaskCount,
                            totalCount: totalTaskCount,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _TodoListDetailPage(
                                    listId: list.id,
                                    visibility: list.visibility,
                                    initialLayoutMode: _layoutMode,
                                    onLayoutModeChanged: (mode) {
                                      if (mounted) {
                                        setState(() => _layoutMode = mode);
                                      }
                                    },
                                    onEditList:
                                        (callbackContext, currentList) =>
                                            _showListDialog(
                                      context: callbackContext,
                                      visibility: currentList.visibility,
                                      existing: currentList,
                                    ),
                                    onDeleteList:
                                        (callbackContext, currentList) =>
                                            _confirmDeleteList(
                                      callbackContext,
                                      callbackContext.read<TodoProvider>(),
                                      currentList,
                                    ),
                                    onShowTaskDialog: (
                                      callbackContext,
                                      currentList,
                                      existingTask,
                                    ) =>
                                        _showTaskDialog(
                                      context: callbackContext,
                                      list: currentList,
                                      familyMembers: callbackContext
                                          .read<FamilyProvider>()
                                          .familyMembers,
                                      currentUser: callbackContext
                                          .read<AuthProvider>()
                                          .currentUser,
                                      existing: existingTask,
                                    ),
                                    onDeleteTask: (callbackContext, task) =>
                                        _confirmDeleteTask(
                                      callbackContext,
                                      callbackContext.read<TodoProvider>(),
                                      task,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showListDialog({
    required BuildContext context,
    required TodoListVisibility visibility,
    TodoList? existing,
  }) async {
    final todoProvider = context.read<TodoProvider>();

    final draft = await showDialog<_TodoListDraft>(
      context: context,
      builder: (dialogContext) => _TodoListDialog(existing: existing),
    );

    if (draft == null || !context.mounted) {
      return;
    }

    if (existing == null) {
      await todoProvider.createList(
        title: draft.title,
        description: draft.description,
        visibility: visibility,
      );
    } else {
      await todoProvider.updateList(
        list: existing,
        title: draft.title,
        description: draft.description,
      );
    }

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          todoProvider.errorMessage ??
              (existing == null ? 'List saved' : 'List updated'),
        ),
      ),
    );
  }
 
  Future<void> _showTaskDialog({
    required BuildContext context,
    required TodoList list,
    required List<User> familyMembers,
    required User? currentUser,
    TodoTask? existing,
  }) async {
    final todoProvider = context.read<TodoProvider>();

    final draft = await showDialog<_TodoTaskDraft>(
      context: context,
      builder: (dialogContext) => _TodoTaskDialog(
        list: list,
        familyMembers: familyMembers,
        currentUser: currentUser,
        existing: existing,
        taskStatusLabel: _taskStatusLabel,
        priorityLabel: _priorityLabel,
      ),
    );

    if (draft == null || !context.mounted) {
      return;
    }

    if (existing == null) {
      await todoProvider.createTask(
        list: list,
        title: draft.title,
        notes: draft.notes,
        dueDate: draft.dueDate,
        assigneeIds: draft.assigneeIds,
        status: draft.status,
        priority: draft.priority,
      );
    } else {
      await todoProvider.updateTask(
        task: existing,
        title: draft.title,
        notes: draft.notes,
        dueDate: draft.dueDate,
        assigneeIds: draft.assigneeIds,
        status: draft.status,
        priority: draft.priority,
      );
    }

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          todoProvider.errorMessage ??
              (existing == null ? 'Task saved' : 'Task updated'),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteList(
    BuildContext context,
    TodoProvider todoProvider,
    TodoList list,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete List'),
            content: Text('Delete "${list.title}" and all of its tasks?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await todoProvider.deleteList(list);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(todoProvider.errorMessage ?? 'List deleted'),
      ),
    );
  }

  Future<void> _confirmDeleteTask(
    BuildContext context,
    TodoProvider todoProvider,
    TodoTask task,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await todoProvider.deleteTask(task);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(todoProvider.errorMessage ?? 'Task deleted'),
      ),
    );
  }

  String _taskStatusLabel(TodoTaskStatus status) {
    final strings = AppStrings.of(context);
    switch (status) {
      case TodoTaskStatus.todo:
        return strings.taskStatusTodo;
      case TodoTaskStatus.inProgress:
        return strings.taskStatusInProgress;
      case TodoTaskStatus.blocked:
        return strings.taskStatusBlocked;
      case TodoTaskStatus.completed:
        return strings.taskStatusCompleted;
    }
  }

  String _priorityLabel(TodoTaskPriority priority) {
    final strings = AppStrings.of(context);
    switch (priority) {
      case TodoTaskPriority.high:
        return strings.priorityHigh;
      case TodoTaskPriority.medium:
        return strings.priorityMedium;
      case TodoTaskPriority.low:
        return strings.priorityLow;
    }
  }
}

class _TodoListDetailPage extends StatefulWidget {
  final String listId;
  final TodoListVisibility visibility;
  final TodoLayoutMode initialLayoutMode;
  final ValueChanged<TodoLayoutMode> onLayoutModeChanged;
  final Future<void> Function(BuildContext context, TodoList list) onEditList;
  final Future<void> Function(BuildContext context, TodoList list)
      onDeleteList;
  final Future<void> Function(
    BuildContext context,
    TodoList list,
    TodoTask? existingTask,
  )
      onShowTaskDialog;
  final Future<void> Function(BuildContext context, TodoTask task)
      onDeleteTask;

  const _TodoListDetailPage({
    required this.listId,
    required this.visibility,
    required this.initialLayoutMode,
    required this.onLayoutModeChanged,
    required this.onEditList,
    required this.onDeleteList,
    required this.onShowTaskDialog,
    required this.onDeleteTask,
  });

  @override
  State<_TodoListDetailPage> createState() => _TodoListDetailPageState();
}

class _TodoListDetailPageState extends State<_TodoListDetailPage> {
  late TodoTaskSortOption _sortOption;
  late bool _showCompleted;
  late TodoLayoutMode _layoutMode;
  bool _didPopMissingList = false;

  @override
  void initState() {
    super.initState();
    _sortOption = TodoTaskSortOption.dueDate;
    _showCompleted = false;
    _layoutMode = widget.initialLayoutMode;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<TodoProvider, FamilyProvider, AuthProvider>(
      builder: (context, todoProvider, familyProvider, authProvider, _) {
        final palette = AppTheme.of(context);
        final currentUser = authProvider.currentUser;
        final lists = widget.visibility == TodoListVisibility.private
            ? todoProvider.privateLists
            : todoProvider.sharedLists;
        final list = _findListById(lists, widget.listId);

        if (list == null) {
          if (!_didPopMissingList) {
            _didPopMissingList = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: BoxDecoration(gradient: palette.pageGradient),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final tasks = todoProvider.tasksForList(
          list.id,
          sortBy: _sortOption,
          includeCompleted: _showCompleted,
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: palette.pageGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Column(
                        children: [
                          _TodoListHeader(
                            list: list,
                            sortOption: _sortOption,
                            showCompleted: _showCompleted,
                            onAddTaskPressed: () =>
                                widget.onShowTaskDialog(context, list, null),
                            onSortChanged: (value) {
                              setState(() => _sortOption = value);
                            },
                            onShowCompletedChanged: (value) {
                              setState(() => _showCompleted = value);
                            },
                            onEditPressed: () => widget.onEditList(context, list),
                            onDeletePressed: () async {
                              await widget.onDeleteList(context, list);
                              if (mounted && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            topTrailing: _SegmentGroupCard(
                              title: 'View',
                              child: SegmentedButton<TodoLayoutMode>(
                                segments: const [
                                  ButtonSegment<TodoLayoutMode>(
                                    value: TodoLayoutMode.compact,
                                    icon: Icon(Icons.view_headline_rounded),
                                    label: Text('Compact'),
                                  ),
                                  ButtonSegment<TodoLayoutMode>(
                                    value: TodoLayoutMode.detailed,
                                    icon: Icon(Icons.view_agenda_outlined),
                                    label: Text('Detailed'),
                                  ),
                                ],
                                selected: {_layoutMode},
                                onSelectionChanged: (value) {
                                  setState(() => _layoutMode = value.first);
                                  widget.onLayoutModeChanged(value.first);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: tasks.isEmpty
                                ? _EmptyTaskState(
                                    list: list,
                                    onCreatePressed: () =>
                                        widget.onShowTaskDialog(
                                      context,
                                      list,
                                      null,
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: tasks.length,
                                    itemBuilder: (context, index) {
                                      final task = tasks[index];
                                      final assignees = _assigneesForTask(
                                        task,
                                        familyProvider.familyMembers,
                                        currentUser,
                                      );

                                      return _layoutMode ==
                                              TodoLayoutMode.compact
                                          ? _CompactTaskTile(
                                              task: task,
                                              selectedList: list,
                                              assignees: assignees,
                                              onToggleCompleted: (value) async {
                                                await todoProvider
                                                    .updateTaskStatus(
                                                  task: task,
                                                  status: value
                                                      ? TodoTaskStatus.completed
                                                      : TodoTaskStatus.todo,
                                                );
                                              },
                                              onTap: () =>
                                                  widget.onShowTaskDialog(
                                                context,
                                                list,
                                                task,
                                              ),
                                              onCreateEventPressed: () =>
                                                  _openTaskEvent(context, task),
                                              onDeletePressed: () =>
                                                  widget.onDeleteTask(
                                                context,
                                                task,
                                              ),
                                            )
                                          : _TaskCard(
                                              task: task,
                                              selectedList: list,
                                              assignees: assignees,
                                              onStatusChanged: (status) async {
                                                await todoProvider
                                                    .updateTaskStatus(
                                                  task: task,
                                                  status: status,
                                                );
                                              },
                                              onEditPressed: () =>
                                                  widget.onShowTaskDialog(
                                                context,
                                                list,
                                                task,
                                              ),
                                              onCreateEventPressed: () =>
                                                  _openTaskEvent(context, task),
                                              onDeletePressed: () =>
                                                  widget.onDeleteTask(
                                                context,
                                                task,
                                              ),
                                            );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodoListHeader extends StatelessWidget {
  final TodoList list;
  final TodoTaskSortOption sortOption;
  final bool showCompleted;
  final VoidCallback onAddTaskPressed;
  final ValueChanged<TodoTaskSortOption> onSortChanged;
  final ValueChanged<bool> onShowCompletedChanged;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  final Widget? topTrailing;

  const _TodoListHeader({
    required this.list,
    required this.sortOption,
    required this.showCompleted,
    required this.onAddTaskPressed,
    required this.onSortChanged,
    required this.onShowCompletedChanged,
    required this.onEditPressed,
    required this.onDeletePressed,
    this.topTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(palette.isDark ? 0.08 : 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: palette.vibrantOutline.withOpacity(0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.12 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((list.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        list.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                              height: 1.25,
                            ),
                      ),
                    ],
                    if ((list.description ?? '').trim().isEmpty)
                      Text(
                        list.isPrivate ? 'Daily list' : 'Shared family list',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditPressed,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDeletePressed,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (topTrailing != null) ...[
            const SizedBox(height: 10),
            topTrailing!,
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onAddTaskPressed,
                  icon: const Icon(Icons.add_task_outlined),
                  label: const Text('Add Task'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        palette.surfaceAlt.withOpacity(palette.isDark ? 0.3 : 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: DropdownButton<TodoTaskSortOption>(
                    value: sortOption,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: TodoTaskSortOption.dueDate,
                        child: Text('Due Date'),
                      ),
                      DropdownMenuItem(
                        value: TodoTaskSortOption.assignee,
                        child: Text('Assignee'),
                      ),
                      DropdownMenuItem(
                        value: TodoTaskSortOption.priority,
                        child: Text('Priority'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onSortChanged(value);
                      }
                    },
                  ),
                ),
                FilterChip(
                  selected: showCompleted,
                  onSelected: onShowCompletedChanged,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: const Text('Completed'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TodoTask task;
  final TodoList selectedList;
  final List<User> assignees;
  final ValueChanged<TodoTaskStatus> onStatusChanged;
  final VoidCallback onEditPressed;
  final VoidCallback onCreateEventPressed;
  final VoidCallback onDeletePressed;

  const _TaskCard({
    required this.task,
    required this.selectedList,
    required this.assignees,
    required this.onStatusChanged,
    required this.onEditPressed,
    required this.onCreateEventPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.read(context);
    final palette = AppTheme.of(context);
    final statusColor = switch (task.status) {
      TodoTaskStatus.todo => palette.secondary,
      TodoTaskStatus.inProgress => palette.primary,
      TodoTaskStatus.blocked => palette.error,
      TodoTaskStatus.completed => palette.success,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(palette.isDark ? 0.08 : 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: palette.vibrantOutline.withOpacity(0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.1 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        statusColor.withOpacity(0.9),
                        statusColor.withOpacity(0.58),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? palette.textMuted
                                  : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((task.notes ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                height: 1.2,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditPressed();
                    } else if (value == 'create_event') {
                      onCreateEventPressed();
                    } else if (value == 'delete') {
                      onDeletePressed();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'create_event',
                      height: 36,
                      child: Text(strings.createEvent),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      height: 36,
                      child: Text(strings.edit),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 36,
                      child: Text(strings.delete),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(palette.isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withOpacity(0.18),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TodoTaskStatus>(
                      value: task.status,
                      isDense: true,
                      icon: const Icon(Icons.expand_more, size: 16),
                      items: TodoTaskStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                switch (status) {
                                  TodoTaskStatus.todo => 'To-Do',
                                  TodoTaskStatus.inProgress => 'In Progress',
                                  TodoTaskStatus.blocked => 'Blocked',
                                  TodoTaskStatus.completed => 'Completed',
                                },
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          )
                          .toList(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      onChanged: (value) {
                        if (value != null) {
                          onStatusChanged(value);
                        }
                      },
                    ),
                  ),
                ),
                _InfoChip(
                  icon: Icons.flag_outlined,
                  label: switch (task.priority) {
                    TodoTaskPriority.high => 'High',
                    TodoTaskPriority.medium => 'Medium',
                    TodoTaskPriority.low => 'Low',
                  },
                ),
                if (task.dueDate != null)
                  _InfoChip(
                    icon: Icons.event_outlined,
                    label: DateFormat('MMM d').format(task.dueDate!),
                  ),
                if (selectedList.isPrivate)
                  const _InfoChip(
                    icon: Icons.lock_outline,
                    label: 'Private',
                  ),
              ],
            ),
            if (selectedList.isShared && assignees.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: assignees
                    .map(
                      (member) => Chip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        backgroundColor: palette.surfaceAlt.withOpacity(
                          palette.isDark ? 0.3 : 0.68,
                        ),
                        side: BorderSide(
                          color: palette.vibrantOutline.withOpacity(0.25),
                        ),
                        avatar: Icon(
                          Icons.person_outline,
                          size: 16,
                          color: palette.textMuted,
                        ),
                        label: Text(
                          member.displayName,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentGroupCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool dark;

  const _SegmentGroupCard({
    required this.title,
    required this.child,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withOpacity(0.12)
            : palette.surface.withOpacity(palette.isDark ? 0.9 : 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? Colors.white.withOpacity(0.14)
              : palette.vibrantOutline.withOpacity(0.55),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                title == 'Scope' ? Icons.layers_outlined : Icons.tune_outlined,
                size: 14,
                color: dark ? Colors.white70 : palette.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: dark ? Colors.white70 : palette.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _CompactSegmentedButton<T> extends StatelessWidget {
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;

  const _CompactSegmentedButton({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      ),
      child: SegmentedButton<T>(
        segments: segments,
        selected: selected,
        onSelectionChanged: onSelectionChanged,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          textStyle: WidgetStateProperty.all(
            Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _HeroInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroInfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surfaceAlt.withOpacity(palette.isDark ? 0.34 : 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: palette.vibrantOutline.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoListLandingCard extends StatelessWidget {
  final TodoList list;
  final int openCount;
  final int totalCount;
  final VoidCallback onPressed;

  const _TodoListLandingCard({
    required this.list,
    required this.openCount,
    required this.totalCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final markerColor = list.isPrivate ? palette.primary : palette.secondary;
    final strings = AppStrings.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 12),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: markerColor.withOpacity(0.9),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: palette.textPrimary,
                            letterSpacing: 0,
                          ),
                    ),
                    if ((list.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        list.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                              fontSize: 12.5,
                              height: 1.2,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      strings.openOfTotal(openCount, totalCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.textMuted.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoListSelectorChip extends StatelessWidget {
  final TodoList list;
  final bool isSelected;
  final int count;
  final VoidCallback onPressed;

  const _TodoListSelectorChip({
    required this.list,
    required this.isSelected,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final strings = AppStrings.of(context);
    final backgroundColor = isSelected
        ? palette.surfaceAlt.withOpacity(palette.isDark ? 0.4 : 0.92)
        : Colors.white.withOpacity(palette.isDark ? 0.1 : 0.92);
    final borderColor = isSelected
        ? palette.primary.withOpacity(0.55)
        : palette.vibrantOutline.withOpacity(0.42);
    final iconColor = isSelected ? palette.primary : palette.textMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.primary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                list.isPrivate ? Icons.lock_outline : Icons.groups_outlined,
                size: 17,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    list.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isSelected ? palette.textPrimary : null,
                        ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.openOfTotal(count, count),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTaskTile extends StatelessWidget {
  final TodoTask task;
  final TodoList selectedList;
  final List<User> assignees;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onTap;
  final VoidCallback onCreateEventPressed;
  final VoidCallback onDeletePressed;

  const _CompactTaskTile({
    required this.task,
    required this.selectedList,
    required this.assignees,
    required this.onToggleCompleted,
    required this.onTap,
    required this.onCreateEventPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.read(context);
    final palette = AppTheme.of(context);
    final meta = <String>[
      switch (task.priority) {
        TodoTaskPriority.high => 'High',
        TodoTaskPriority.medium => 'Medium',
        TodoTaskPriority.low => 'Low',
      },
      if (task.dueDate != null) DateFormat('M/d').format(task.dueDate!),
      if (selectedList.isShared && assignees.isNotEmpty) assignees.first.displayName,
      if (selectedList.isPrivate) 'Private',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(palette.isDark ? 0.08 : 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.vibrantOutline.withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.08 : 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        horizontalTitleGap: 6,
        minLeadingWidth: 0,
        leading: Checkbox(
          value: task.isCompleted,
          visualDensity: VisualDensity.compact,
          onChanged: (value) {
            if (value != null) {
              onToggleCompleted(value);
            }
          },
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? palette.textMuted : null,
              ),
        ),
        subtitle: meta.isEmpty
            ? null
            : Text(
                meta.join('  •  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.status != TodoTaskStatus.completed)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: switch (task.status) {
                    TodoTaskStatus.todo => palette.secondary,
                    TodoTaskStatus.inProgress => palette.primary,
                    TodoTaskStatus.blocked => palette.error,
                    TodoTaskStatus.completed => palette.success,
                  },
                  shape: BoxShape.circle,
                ),
              ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') {
                  onTap();
                } else if (value == 'create_event') {
                  onCreateEventPressed();
                } else if (value == 'delete') {
                  onDeletePressed();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'create_event',
                  height: 36,
                  child: Text(strings.createEvent),
                ),
                PopupMenuItem(
                  value: 'edit',
                  height: 36,
                  child: Text(strings.edit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  height: 36,
                  child: Text(strings.delete),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surfaceAlt.withOpacity(palette.isDark ? 0.3 : 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: palette.vibrantOutline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTodoState extends StatelessWidget {
  final TodoListVisibility visibility;
  final bool hasFamily;
  final VoidCallback onCreatePressed;

  const _EmptyTodoState({
    required this.visibility,
    required this.hasFamily,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isShared = visibility == TodoListVisibility.shared;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isShared ? Icons.groups_2_outlined : Icons.lock_outline,
              size: 66,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isShared ? 'No shared family lists yet' : 'No private lists yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isShared && !hasFamily
                  ? 'Join a family first, then you can create shared chore boards and collaborative plans here.'
                  : 'Create your first list to start organizing chores, errands, and goals.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: isShared && !hasFamily ? null : onCreatePressed,
              icon: const Icon(Icons.add_outlined),
              label: const Text('Create List'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTaskState extends StatelessWidget {
  final TodoList list;
  final VoidCallback onCreatePressed;

  const _EmptyTaskState({
    required this.list,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    list.isPrivate
                        ? Icons.rule_folder_outlined
                        : Icons.assignment_outlined,
                    size: 62,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks in ${list.title} yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    list.isPrivate
                        ? 'Add your own next steps here. Private tasks stay visible only to you.'
                        : 'Add tasks, assign them to family members, and keep everyone aligned from one shared list.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onCreatePressed,
                    icon: const Icon(Icons.add_task_outlined),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
