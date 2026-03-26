import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/event/add_event_screen.dart';
import '../screens/event/event_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/category_settings_screen.dart';
import '../screens/family/family_members_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Redirect logic will be handled by providers
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Home Route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Calendar Routes
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),

      // Event Routes
      GoRoute(
        path: '/event/add',
        name: 'addEvent',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddEventScreen(
            initialDate: extra?['date'] as DateTime?,
            initialTitle: extra?['title'] as String?,
            initialNotes: extra?['notes'] as String?,
            preferredCategoryName: extra?['preferredCategoryName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/event/:eventId/edit',
        name: 'editEvent',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return AddEventScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/event/:eventId',
        name: 'eventDetail',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return EventDetailScreen(eventId: eventId);
        },
      ),

      // Settings Routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/categories',
        name: 'categorySettings',
        builder: (context, state) => const CategorySettingsScreen(),
      ),

      // Family Routes
      GoRoute(
        path: '/family/members',
        name: 'familyMembers',
        builder: (context, state) => const FamilyMembersScreen(),
      ),
    ],
  );
}
