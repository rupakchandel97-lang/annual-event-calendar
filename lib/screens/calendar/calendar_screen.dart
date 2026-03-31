import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/event_icon_avatar.dart';
import '../../widgets/user_app_bar_title.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static final DateTime _calendarFirstDay = DateTime(2019, 12, 29);
  static final DateTime _calendarLastDay = DateTime(2030, 12, 31);
  static const int _maxVisibleDayMarkers = 2;
  static const double _dayMarkerDiameter = 24;
  static const double _dayOverflowBadgeWidth = 20;

  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const UserAppBarTitle(title: 'Calendar'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              final visibleRange = _getVisibleRange();
              final visibleEvents = eventProvider.getEventsForRange(
                visibleRange.$1,
                visibleRange.$2,
              );
              final copyText = _buildVisibleEventsClipboardText(visibleEvents);

              return IconButton(
                onPressed: copyText.isEmpty
                    ? null
                    : () => _copyVisibleEvents(context, copyText),
                icon: const Icon(Icons.content_copy_outlined),
                tooltip: 'Copy visible events',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                final categoryProvider = context.read<CategoryProvider>();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TableCalendar(
                          firstDay: _calendarFirstDay,
                          lastDay: _calendarLastDay,
                          focusedDay: _focusedDay,
                          startingDayOfWeek: StartingDayOfWeek.sunday,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.twoWeeks: '2 Weeks',
                            CalendarFormat.week: 'Week',
                          },
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          calendarFormat: _calendarFormat,
                          onFormatChanged: (format) {
                            setState(() => _calendarFormat = format);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            setState(() => _focusedDay = focusedDay);
                          },
                          eventLoader: (day) {
                            return eventProvider.getEventsForDate(day);
                          },
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) {
                              if (events.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final dayEvents = events.cast<CalendarEvent>();
                              final hasOverflow =
                                  dayEvents.length > _maxVisibleDayMarkers;
                              final visibleMarkerCount =
                                  hasOverflow ? 1 : _maxVisibleDayMarkers;
                              final visibleEvents = dayEvents
                                  .take(visibleMarkerCount)
                                  .toList();
                              final remainingCount =
                                  dayEvents.length - visibleEvents.length;
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: ClipRect(
                                    child: SizedBox(
                                      height: _dayMarkerDiameter,
                                      width: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (final event in visibleEvents)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 1,
                                                ),
                                                child: _buildCalendarMarker(
                                                  context: context,
                                                  categoryProvider:
                                                      categoryProvider,
                                                  event: event,
                                                ),
                                              ),
                                            if (remainingCount > 0)
                                              Container(
                                                width: _dayOverflowBadgeWidth,
                                                height: _dayOverflowBadgeWidth,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                                  ),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                    child: Text(
                                                      '+$remainingCount',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          calendarStyle: CalendarStyle(
                            canMarkersOverflow: false,
                            todayDecoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          daysOfWeekHeight: 40,
                          rowHeight: 100,
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekendStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          holidayPredicate: (day) => false,
                        ),
                      ),
                      _buildRangeEventsPanel(eventProvider, categoryProvider),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeEventsPanel(
    EventProvider eventProvider,
    CategoryProvider categoryProvider,
  ) {
    final visibleRange = _getVisibleRange();
    final events = eventProvider.getEventsForRange(
      visibleRange.$1,
      visibleRange.$2,
    );

    final heading = switch (_calendarFormat) {
      CalendarFormat.week => 'Week Overview',
      CalendarFormat.twoWeeks => '2-Week Overview',
      CalendarFormat.month => 'Month Overview',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('MMM d').format(visibleRange.$1)} - ${DateFormat('MMM d, yyyy').format(visibleRange.$2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 12),
          _buildEventsList(events, categoryProvider),
        ],
      ),
    );
  }

  (DateTime, DateTime) _getVisibleRange() {
    switch (_calendarFormat) {
      case CalendarFormat.week:
        final start = _startOfWeek(_focusedDay);
        return (start, start.add(const Duration(days: 6)));
      case CalendarFormat.twoWeeks:
        final start = _startOfWeek(_focusedDay);
        return (start, start.add(const Duration(days: 13)));
      case CalendarFormat.month:
        final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
        final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
        return (start, end);
    }
  }

  Future<void> _copyVisibleEvents(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visible events copied')),
    );
  }

  String _buildVisibleEventsClipboardText(List<CalendarEvent> events) {
    final visibleRange = _getVisibleRange();
    final sortedEvents = [...events]
      ..sort((a, b) {
        final aDate = a.firstOccurrenceInRange(visibleRange.$1, visibleRange.$2) ??
            a.date;
        final bDate = b.firstOccurrenceInRange(visibleRange.$1, visibleRange.$2) ??
            b.date;
        final dateCompare = aDate.compareTo(bDate);
        if (dateCompare != 0) {
          return dateCompare;
        }

        final aTime = a.startTime;
        final bTime = b.startTime;
        if (aTime == null && bTime == null) {
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
        if (aTime == null) {
          return -1;
        }
        if (bTime == null) {
          return 1;
        }

        final timeCompare = aTime.compareTo(bTime);
        if (timeCompare != 0) {
          return timeCompare;
        }

        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    return sortedEvents
        .map((event) {
          final occurrenceDate =
              event.firstOccurrenceInRange(visibleRange.$1, visibleRange.$2) ??
                  event.date;
          return [
            event.title.trim(),
            DateFormat('MMM d, yyyy').format(occurrenceDate),
            _formatClipboardTimeLabel(event),
          ].join('\t');
        })
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }

  String _formatClipboardTimeLabel(CalendarEvent event) {
    if (event.allDay) {
      return 'All day';
    }

    final startTime = event.startTime;
    final endTime = event.endTime;
    if (startTime == null) {
      return '';
    }

    final formatter = DateFormat('HH:mm');
    if (endTime == null) {
      return formatter.format(startTime);
    }

    return '${formatter.format(startTime)} - ${formatter.format(endTime)}';
  }

  DateTime _startOfWeek(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final daysFromSunday = day.weekday % 7;
    return normalizedDay.subtract(Duration(days: daysFromSunday));
  }

  Widget _buildCalendarMarker({
    required BuildContext context,
    required CategoryProvider categoryProvider,
    required CalendarEvent event,
  }) {
    final category = categoryProvider.getCategoryById(event.categoryId);
    final markerColor = category?.color ?? Theme.of(context).colorScheme.primary;

    if (event.iconAssetPath != null && event.iconAssetPath!.isNotEmpty) {
      return Container(
        width: _dayMarkerDiameter,
        height: _dayMarkerDiameter,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          shape: BoxShape.circle,
          border: Border.all(color: markerColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(
            event.iconAssetPath!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEventsList(
    List<CalendarEvent> events,
    CategoryProvider categoryProvider,
  ) {
    if (events.isEmpty) {
      return Text(
        'No events scheduled in this range',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final category = categoryProvider.getCategoryById(event.categoryId);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: EventIconAvatar(
              assetPath: event.iconAssetPath,
              backgroundColor: category?.color ?? Colors.grey,
              radius: 20,
              iconSize: 20,
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatEventDateLabel(event)),
                if (event.location != null && event.location!.isNotEmpty)
                  Text('Location: ${event.location}'),
                if (!event.allDay && event.startTime != null)
                  Text(
                    'Time: ${DateFormat('HH:mm').format(event.startTime!)} - ${event.endTime != null ? DateFormat('HH:mm').format(event.endTime!) : 'Open end'}',
                  ),
              ],
            ),
            onTap: () => context.go('/event/${event.id}'),
          ),
        );
      },
    );
  }

  String _formatEventDateLabel(CalendarEvent event) {
    if (event.isRecurring) {
      final visibleRange = _getVisibleRange();
      final nextOccurrence =
          event.firstOccurrenceInRange(visibleRange.$1, visibleRange.$2);
      final nextLabel = nextOccurrence == null
          ? 'Repeats ${event.recurrence.name}'
          : 'Occurs ${DateFormat('MMM d, yyyy').format(nextOccurrence)}';

      if (event.recurrence == RecurrenceType.weekly) {
        final weekdays = event.effectiveRecurrenceWeekdays
            .map(_weekdayShortLabel)
            .join(', ');
        return 'Weekly on $weekdays - $nextLabel';
      }

      return '${_titleCase(event.recurrence.name)} - $nextLabel';
    }

    final startLabel = DateFormat('MMM d, yyyy').format(event.date);
    if (!event.isMultiDay || event.endDate == null) {
      return startLabel;
    }

    return '$startLabel - ${DateFormat('MMM d, yyyy').format(event.endDate!)}';
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

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
