import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/event_icon_avatar.dart';
import '../../widgets/user_app_bar_title.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _loadedFamilyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    final authProvider = context.read<AuthProvider>();
    final familyProvider = context.read<FamilyProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final eventProvider = context.read<EventProvider>();

    if (authProvider.currentUser != null) {
      final familyId = authProvider.currentUser?.familyId;
      if (familyId != null && familyId != _loadedFamilyId) {
        _loadedFamilyId = familyId;
        familyProvider.loadFamily(familyId);
        categoryProvider.loadCategories(familyId);
        eventProvider.loadEventsForContext(
          familyId: familyId,
          userId: authProvider.currentUser?.uid,
          userEmail: authProvider.currentUser?.email,
        );
      }
    }
  }

  void _clearLoadedData() {
    _loadedFamilyId = null;
    context.read<FamilyProvider>().clear();
    context.read<CategoryProvider>().clear();
    context.read<EventProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const UserAppBarTitle(title: 'Family Calendar'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              _clearLoadedData();
              context.read<AuthProvider>().signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.currentUser == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _clearLoadedData();
              context.go('/login');
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (authProvider.currentUser?.familyId != null &&
              authProvider.currentUser!.familyId != _loadedFamilyId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _initializeData();
              }
            });
          }

          return Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildCalendarView(),
                    _buildAgendaView(),
                    _buildTodoView(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_view_month_outlined),
            selectedIcon: Icon(Icons.calendar_view_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_agenda_outlined),
            selectedIcon: Icon(Icons.view_agenda_rounded),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'To-Do',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/event/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Calendar View'),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: () => context.go('/calendar'),
              child: const Text('Open Calendar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaView() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final upcomingEvents = eventProvider.getUpcomingEvents();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Text(
                'Shows events due today or in the future. To view past events, check Calendar view.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
              ),
            ),
            Expanded(
              child: upcomingEvents.isEmpty
                  ? const Center(
                      child: Text('No upcoming events'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: upcomingEvents.length,
                      itemBuilder: (context, index) {
                        final event = upcomingEvents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: EventIconAvatar(
                              assetPath: event.iconAssetPath,
                              backgroundColor: Color(
                                context
                                        .read<CategoryProvider>()
                                        .getCategoryById(event.categoryId)
                                        ?.colorValue ??
                                    0xFF2196F3,
                              ),
                              radius: 20,
                              iconSize: 20,
                            ),
                            title: Text(event.title),
                            subtitle: Text(_buildAgendaSubtitle(event)),
                            onTap: () => context.go('/event/${event.id}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodoView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checklist, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('To-Do Lists & Grocery List'),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              ),
              child: const Text('Manage Lists'),
            ),
          ),
        ],
      ),
    );
  }

  String _buildAgendaSubtitle(CalendarEvent event) {
    if (event.isRecurring) {
      final nextOccurrence = event.nextOccurrenceOnOrAfter(DateTime.now());
      final nextLabel = nextOccurrence == null
          ? 'No upcoming date'
          : 'Next: ${DateFormat('M/d/yyyy').format(nextOccurrence)}';

      if (event.recurrence == RecurrenceType.weekly) {
        final weekdays = event.effectiveRecurrenceWeekdays
            .map(_weekdayShortLabel)
            .join(', ');
        return 'Weekly on $weekdays - $nextLabel';
      }

      return '${_titleCase(event.recurrence.name)} - $nextLabel';
    }

    if (event.isMultiDay && event.endDate != null) {
      return '${event.date.month}/${event.date.day}/${event.date.year} - ${event.endDate!.month}/${event.endDate!.day}/${event.endDate!.year}';
    }

    return '${event.date.month}/${event.date.day}/${event.date.year}';
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
