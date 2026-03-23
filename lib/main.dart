import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/category_provider.dart';
import 'providers/family_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
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
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Family Calendar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeDataFor(themeProvider.themeId),
            themeMode: ThemeMode.light,
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
