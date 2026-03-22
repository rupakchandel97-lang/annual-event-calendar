import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/category_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
      if (familyId != null) {
        familyProvider.loadFamily(familyId);
        categoryProvider.loadCategories(familyId);
        eventProvider.loadEvents(familyId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Calendar'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
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
              context.go('/login');
            });
            return const Center(child: CircularProgressIndicator());
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
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
          ElevatedButton(
            onPressed: () => context.go('/calendar'),
            child: const Text('Open Calendar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaView() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final upcomingEvents = eventProvider.events
            .where((event) => event.date.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (upcomingEvents.isEmpty) {
          return const Center(
            child: Text('No upcoming events'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingEvents.length,
          itemBuilder: (context, index) {
            final event = upcomingEvents[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    context
                            .read<CategoryProvider>()
                            .getCategoryById(event.categoryId)
                            ?.colorValue ??
                        0xFF2196F3,
                  ),
                ),
                title: Text(event.title),
                subtitle: Text(
                  '${event.date.month}/${event.date.day}/${event.date.year}',
                ),
                onTap: () => context.go('/event/${event.id}'),
              ),
            );
          },
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
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feature coming soon')),
            ),
            child: const Text('Manage Lists'),
          ),
        ],
      ),
    );
  }
}
