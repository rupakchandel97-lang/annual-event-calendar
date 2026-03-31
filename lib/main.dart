import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/category_provider.dart';
import 'providers/family_provider.dart';
import 'providers/household_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/todo_provider.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase, ignoring duplicate-app errors from hot restart
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
    // Silently ignore duplicate-app in development/hot-restart
  } catch (e) {
    // Re-throw any other unexpected errors
    rethrow;
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(const FamilyCalendarApp());
}

class FamilyCalendarApp extends StatelessWidget {
  const FamilyCalendarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ThemeProvider>(
          create: (_) => ThemeProvider(),
          update: (_, authProvider, themeProvider) {
            final provider = themeProvider ?? ThemeProvider();
            provider.syncWithUserTheme(authProvider.currentUser?.themeId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, LocaleProvider>(
          create: (_) => LocaleProvider(),
          update: (_, authProvider, localeProvider) {
            final provider = localeProvider ?? LocaleProvider();
            provider.syncWithUserLanguage(authProvider.currentUser?.languageCode);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationService>(
          create: (_) => NotificationService(),
          update: (_, authProvider, notificationService) {
            final service = notificationService ?? NotificationService();
            service.syncSession(authProvider.currentUser);
            return service;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, TodoProvider>(
          create: (_) => TodoProvider(),
          update: (_, authProvider, todoProvider) {
            final provider = todoProvider ?? TodoProvider();
            provider.syncSession(
              userId: authProvider.currentUser?.uid,
              familyId: authProvider.currentUser?.familyId,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, HouseholdProvider>(
          create: (_) => HouseholdProvider(),
          update: (_, authProvider, householdProvider) {
            final provider = householdProvider ?? HouseholdProvider();
            provider.syncSession(
              userId: authProvider.currentUser?.uid,
              familyId: authProvider.currentUser?.familyId,
            );
            return provider;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp.router(
            title: 'Family Calendar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeDataFor(themeProvider.themeId),
            themeMode: ThemeMode.light,
            locale: localeProvider.locale,
            builder: (context, child) {
              return Container(
                decoration: AppTheme.backgroundDecorationFor(themeProvider.themeId),
                child: child,
              );
            },
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
