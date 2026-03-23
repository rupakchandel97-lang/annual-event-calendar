import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    } else {
      throw UnsupportedError(
        'DefaultFirebaseOptions is not supported for this platform.',
      );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCX7UCl-yDu8hTOT7DFvKsl2HhXKKcohZk',
    appId: '1:799894490699:android:a63588311d7bbb2d3187ce',
    messagingSenderId: '799894490699',
    projectId: 'family-calendar-684de',
    storageBucket: 'family-calendar-684de.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyIOSKeyReplace',
    appId: '1:123456789:ios:dummyappidreplace',
    messagingSenderId: '123456789',
    projectId: 'family-calendar-684de',
    storageBucket: 'family-calendar-684de.firebasestorage.app',
    iosBundleId: 'com.example.familyCalendar',
  );
}
