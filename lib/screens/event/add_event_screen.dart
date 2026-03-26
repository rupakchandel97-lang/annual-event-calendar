import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/event_icon_assets.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/event_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_icon_avatar.dart';
import '../../widgets/user_app_bar_title.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? eventId;
  final String? initialTitle;
  final String? initialNotes;
  final String? preferredCategoryName;

  const AddEventScreen({
    Key? key,
    this.initialDate,
    this.eventId,
    this.initialTitle,
    this.initialNotes,
    this.preferredCategoryName,
  }) : super(key: key);

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  static const List<int> _weekdayOrder = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  late DateTime _selectedDate;
  late DateTime _selectedEndDate;
  late DateTime? _startTime;
  late DateTime? _endTime;
  bool _allDay = false;
  bool _didLoadExistingEvent = false;
  RecurrenceType _recurrence = RecurrenceType.none;
  DateTime? _recurrenceEndDate;
  final Set<int> _selectedWeekdays = <int>{};

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedIconAssetPath;
  late final Future<List<String>> _iconPathsFuture;

  bool get _isEditing => widget.eventId != null;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    if (_isEditing) {
      context.go('/event/${widget.eventId}');
      return;
    }

    context.go('/');
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedEndDate = _selectedDate;
    _startTime = null;
    _endTime = null;
    _titleController.text = widget.initialTitle ?? '';
    _notesController.text = widget.initialNotes ?? '';
    _iconPathsFuture = EventIconAssets.loadPaths();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final familyId = authProvider.currentUser?.familyId;
      if (familyId != null && categoryProvider.categories.isEmpty) {
        categoryProvider.loadCategories(familyId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditing && !_didLoadExistingEvent) {
      final existingEvent =
          context.read<EventProvider>().getEventById(widget.eventId!);
      if (existingEvent != null) {
        _loadExistingEvent(existingEvent);
      }
      _didLoadExistingEvent = true;
    }
  }

  void _loadExistingEvent(CalendarEvent event) {
    _titleController.text = event.title;
    _locationController.text = event.location ?? '';
    _notesController.text = event.notes ?? '';
    _selectedDate = event.date;
    _selectedEndDate = event.endDate ?? event.date;
    _startTime = event.startTime;
    _endTime = event.endTime;
    _allDay = event.allDay;
    _recurrence = event.recurrence;
    _recurrenceEndDate = event.recurrenceEndDate;
    _selectedWeekdays
      ..clear()
      ..addAll(event.effectiveRecurrenceWeekdays);
    _selectedCategoryId = event.categoryId;
    _selectedIconAssetPath = event.iconAssetPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        if (_selectedEndDate.isBefore(_selectedDate)) {
          _selectedEndDate = _selectedDate;
        }
        if (_startTime != null) {
          _startTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _startTime!.hour,
            _startTime!.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedEndDate = pickedDate;
        if (_endTime != null) {
          _endTime = DateTime(
            _selectedEndDate.year,
            _selectedEndDate.month,
            _selectedEndDate.day,
            _endTime!.hour,
            _endTime!.minute,
          );
        }
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final targetDate = isStartTime ? _selectedDate : _selectedEndDate;
      final dateTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      setState(() {
        if (isStartTime) {
          _startTime = dateTime;
        } else {
          _endTime = dateTime;
        }
      });
    }
  }

  Future<void> _showIconPicker() async {
    final strings = AppStrings.read(context);
    final iconPaths = await _iconPathsFuture;
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.chooseEventIcon,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: iconPaths.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedIconAssetPath == null;
                        return _IconChoiceTile(
                          label: strings.none,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedIconAssetPath = null);
                            sheetContext.pop();
                          },
                          child: const Icon(Icons.block_outlined),
                        );
                      }

                      final assetPath = iconPaths[index - 1];
                      final isSelected = assetPath == _selectedIconAssetPath;
                      return _IconChoiceTile(
                        label: EventIconAssets.labelFor(assetPath),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedIconAssetPath = assetPath);
                          sheetContext.pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(assetPath, fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectRecurrenceEndDate() async {
    final initialDate = _recurrenceEndDate ?? _selectedDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(_selectedDate) ? _selectedDate : initialDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() => _recurrenceEndDate = pickedDate);
    }
  }

  void _handleRecurrenceChanged(RecurrenceType? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _recurrence = value;
      if (_recurrence != RecurrenceType.weekly) {
        _selectedWeekdays.clear();
      } else if (_selectedWeekdays.isEmpty) {
        _selectedWeekdays.add(_selectedDate.weekday);
      }

      if (_recurrence == RecurrenceType.none) {
        _recurrenceEndDate = null;
      }
    });
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(weekday);
        }
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  String _recurrenceLabel(RecurrenceType value) {
    final strings = AppStrings.read(context);
    switch (value) {
      case RecurrenceType.none:
        return strings.doesNotRepeat;
      case RecurrenceType.daily:
        return strings.daily;
      case RecurrenceType.weekly:
        return strings.weekly;
      case RecurrenceType.monthly:
        return strings.monthly;
      case RecurrenceType.yearly:
        return strings.yearly;
    }
  }

  String _weekdayShortLabel(int weekday) {
    const labels = <int, String>{
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };

    return labels[weekday] ?? '';
  }

  Future<void> _saveEvent() async {
    final strings = AppStrings.read(context);
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.pleaseEnterEventTitle)),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.pleaseSelectCategory)),
      );
      return;
    }

    if (_selectedEndDate.isBefore(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.endDateBeforeStartDate)),
      );
      return;
    }

    if (!_allDay &&
        _startTime != null &&
        _endTime != null &&
        !_endTime!.isAfter(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.endTimeBeforeStartTime)),
      );
      return;
    }

    if (_recurrence != RecurrenceType.none &&
        _recurrenceEndDate != null &&
        _recurrenceEndDate!.isBefore(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.recurrenceEndBeforeEventDate)),
      );
      return;
    }

    if (_recurrence == RecurrenceType.weekly && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.selectWeeklyRecurrenceDay)),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    final familyId = authProvider.currentUser?.familyId;
    if (familyId == null) {
      return;
    }

    if (_isEditing) {
      await eventProvider.updateEvent(
        eventId: widget.eventId!,
        title: _titleController.text.trim(),
        date: _selectedDate,
        endDate: _selectedEndDate,
        categoryId: _selectedCategoryId!,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        startTime: _allDay ? null : _startTime,
        endTime: _allDay ? null : _endTime,
        recurrence: _recurrence,
        recurrenceEndDate: _recurrenceEndDate,
        recurrenceWeekdays: _recurrence == RecurrenceType.weekly
            ? (_selectedWeekdays.toList()..sort())
            : const [],
        allDay: _allDay,
        iconAssetPath: _selectedIconAssetPath,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.eventUpdatedSuccessfully)),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/event/${widget.eventId}');
      }
      return;
    }

    await eventProvider.addEvent(
      familyId: familyId,
      title: _titleController.text.trim(),
      date: _selectedDate,
      endDate: _selectedEndDate,
      categoryId: _selectedCategoryId!,
      createdBy: authProvider.currentUser!.uid,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      startTime: _allDay ? null : _startTime,
      endTime: _allDay ? null : _endTime,
      recurrence: _recurrence,
      recurrenceEndDate: _recurrenceEndDate,
      recurrenceWeekdays: _recurrence == RecurrenceType.weekly
          ? (_selectedWeekdays.toList()..sort())
          : const [],
      allDay: _allDay,
      iconAssetPath: _selectedIconAssetPath,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.eventAddedSuccessfully)),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final palette = AppTheme.of(context);
    final pickerFillColor = palette.vibrantSurfaceAlt.withOpacity(
      palette.isDark ? 0.54 : 0.72,
    );
    final pickerBorderColor = palette.vibrantOutline.withOpacity(0.92);
    final pickerIconColor = palette.secondary;
    final pickerTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        );
    final pickerHintStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: palette.textMuted,
          fontWeight: FontWeight.w500,
        );
    final categoryColor = context
            .read<CategoryProvider>()
            .getCategoryById(_selectedCategoryId ?? '')
            ?.color ??
        Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: UserAppBarTitle(title: _isEditing ? strings.editEvent : strings.addEvent),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: strings.eventTitle,
                prefixIcon: const Icon(Icons.event_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: pickerBorderColor),
                        borderRadius: BorderRadius.circular(8),
                        color: pickerFillColor,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: pickerIconColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: pickerTextStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: pickerBorderColor),
                        borderRadius: BorderRadius.circular(8),
                        color: pickerFillColor,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_repeat_outlined,
                            color: pickerIconColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat('MMM d, yyyy').format(_selectedEndDate),
                              overflow: TextOverflow.ellipsis,
                              style: pickerTextStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedEndDate.isAfter(_selectedDate))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  strings.spansDays(
                    _selectedEndDate.difference(_selectedDate).inDays + 1,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            SwitchListTile(
              title: Text(strings.allDay),
              value: _allDay,
              onChanged: (value) => setState(() => _allDay = value),
            ),
            if (!_allDay) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: pickerBorderColor),
                          borderRadius: BorderRadius.circular(8),
                          color: pickerFillColor,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              color: pickerIconColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _startTime != null
                                    ? DateFormat('HH:mm').format(_startTime!)
                                    : strings.startTime,
                                overflow: TextOverflow.ellipsis,
                                style: _startTime != null
                                    ? pickerTextStyle
                                    : pickerHintStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: pickerBorderColor),
                          borderRadius: BorderRadius.circular(8),
                          color: pickerFillColor,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              color: pickerIconColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _endTime != null
                                    ? DateFormat('HH:mm').format(_endTime!)
                                    : strings.endTime,
                                overflow: TextOverflow.ellipsis,
                                style: _endTime != null
                                    ? pickerTextStyle
                                    : pickerHintStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceType>(
              value: _recurrence,
              decoration: InputDecoration(
                hintText: strings.repeat,
                prefixIcon: const Icon(Icons.repeat),
              ),
              items: RecurrenceType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_recurrenceLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: _handleRecurrenceChanged,
            ),
            if (_recurrence == RecurrenceType.weekly) ...[
              const SizedBox(height: 12),
              Text(
                strings.repeatOn,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weekdayOrder.map((weekday) {
                  final isSelected = _selectedWeekdays.contains(weekday);
                  return FilterChip(
                    label: Text(_weekdayShortLabel(weekday)),
                    selected: isSelected,
                    selectedColor: palette.primary.withOpacity(
                      palette.isDark ? 0.34 : 0.2,
                    ),
                    backgroundColor: palette.vibrantSurface,
                    side: BorderSide(
                      color: isSelected ? palette.primary : pickerBorderColor,
                    ),
                    checkmarkColor: palette.primary,
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? palette.textPrimary
                              : palette.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                    onSelected: (_) => _toggleWeekday(weekday),
                  );
                }).toList(),
              ),
            ],
            if (_recurrence != RecurrenceType.none) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectRecurrenceEndDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: pickerBorderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: pickerFillColor,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        color: pickerIconColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _recurrenceEndDate == null
                              ? strings.noRecurrenceEndDate
                              : strings.repeatUntil(
                                  DateFormat('MMM d, yyyy').format(
                                    _recurrenceEndDate!,
                                  ),
                                ),
                          style: _recurrenceEndDate == null
                              ? pickerHintStyle
                              : pickerTextStyle,
                        ),
                      ),
                      if (_recurrenceEndDate != null)
                        IconButton(
                          tooltip: strings.clearRecurrenceEndDate,
                          onPressed: () => setState(() => _recurrenceEndDate = null),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, _) {
                if (categoryProvider.categories.isEmpty) {
                  return Text(strings.noCategoriesAvailable);
                }

                if (_selectedCategoryId == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _selectedCategoryId != null) {
                      return;
                    }
                    String resolvedCategoryId = categoryProvider.categories.first.id;
                    final preferredName =
                        (widget.preferredCategoryName ?? '').trim().toLowerCase();
                    if (preferredName.isNotEmpty) {
                      for (final category in categoryProvider.categories) {
                        if (category.name.trim().toLowerCase() == preferredName) {
                          resolvedCategoryId = category.id;
                          break;
                        }
                      }
                    }
                    setState(() => _selectedCategoryId = resolvedCategoryId);
                  });
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    hintText: strings.selectCategory,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: categoryProvider.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: category.color,
                                radius: 8,
                              ),
                              const SizedBox(width: 12),
                              Text(category.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                );
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showIconPicker,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.vibrantSurface.withOpacity(
                    palette.isDark ? 0.92 : 0.9,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: pickerBorderColor),
                ),
                child: Row(
                  children: [
                    EventIconAvatar(
                      assetPath: _selectedIconAssetPath,
                      backgroundColor: categoryColor,
                      radius: 24,
                      iconSize: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.eventIcon,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedIconAssetPath == null
                                ? strings.chooseEventIconHint
                                : EventIconAssets.labelFor(
                                    _selectedIconAssetPath!,
                                  ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: strings.location,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: strings.notesLabel,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goBack,
                    child: Text(strings.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveEvent,
                    child: Text(_isEditing ? strings.saveChanges : strings.saveEvent),
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

class _IconChoiceTile extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconChoiceTile({
    required this.child,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.14)
              : AppTheme.of(context).vibrantSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : AppTheme.of(context).vibrantOutline.withOpacity(0.9),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Center(child: child)),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
