import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/family_provider.dart';
import '../../widgets/event_icon_avatar.dart';
import '../../widgets/user_app_bar_title.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBack(context),
        ),
        title: const UserAppBarTitle(title: 'Event Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/event/$eventId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Event'),
                  content: const Text('Are you sure you want to delete this event?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<EventProvider>().deleteEvent(eventId);
                        context.pop();
                        context.go('/');
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, _) {
          final event = eventProvider.getEventById(eventId);

          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          final category =
              context.read<CategoryProvider>().getCategoryById(event.categoryId);
          final assignedUser = _findAssignedUser(
            context.read<FamilyProvider>().familyMembers,
            event.assignedToUserId,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: category?.color ?? Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EventIconAvatar(
                            assetPath: event.iconAssetPath,
                            backgroundColor: Colors.white,
                            radius: 24,
                            iconSize: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              event.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Event Details
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: event.isMultiDay ? 'Dates' : 'Date',
                  value: _formatEventDateRange(event),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.repeat,
                  label: 'Recurrence',
                  value: _formatRecurrence(event),
                ),
                const SizedBox(height: 16),

                if (!event.allDay && event.startTime != null)
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Time',
                    value:
                        '${DateFormat('HH:mm').format(event.startTime!)} - ${event.endTime != null ? DateFormat('HH:mm').format(event.endTime!) : 'No end time'}',
                  ),

                if (event.allDay)
                  _DetailRow(
                    icon: Icons.schedule_outlined,
                    label: 'Type',
                    value: 'All Day Event',
                  ),

                if (event.location != null && event.location!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: event.location!,
                  ),
                ],

                if (assignedUser != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outlined),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assigned To',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(assignedUser.displayName),
                        ],
                      ),
                    ],
                  ),
                ],

                if (event.notes != null && event.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(event.notes!),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Created on ${DateFormat('MMM d, yyyy').format(event.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  User? _findAssignedUser(List<User> familyMembers, String? assignedToUserId) {
    if (assignedToUserId == null) {
      return null;
    }

    for (final user in familyMembers) {
      if (user.uid == assignedToUserId) {
        return user;
      }
    }

    return null;
  }

  String _formatEventDateRange(CalendarEvent event) {
    final startLabel = DateFormat('MMMM d, yyyy').format(event.date);
    if (!event.isMultiDay || event.endDate == null) {
      return startLabel;
    }

    return '$startLabel - ${DateFormat('MMMM d, yyyy').format(event.endDate!)}';
  }

  String _formatRecurrence(CalendarEvent event) {
    if (!event.isRecurring) {
      return 'Does not repeat';
    }

    final endLabel = event.recurrenceEndDate == null
        ? 'No end date'
        : 'Until ${DateFormat('MMMM d, yyyy').format(event.recurrenceEndDate!)}';

    switch (event.recurrence) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return 'Repeats daily. $endLabel';
      case RecurrenceType.weekly:
        final weekdays = event.effectiveRecurrenceWeekdays
            .map((day) => _weekdayShortLabel(day))
            .join(', ');
        return 'Repeats weekly on $weekdays. $endLabel';
      case RecurrenceType.monthly:
        return 'Repeats monthly on day ${event.date.day}. $endLabel';
      case RecurrenceType.yearly:
        return 'Repeats yearly on ${DateFormat('MMMM d').format(event.date)}. $endLabel';
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
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(value),
          ],
        ),
      ],
    );
  }
}
