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
    apiKey: 'AIzaSyDummyAndroidKeyReplace',
    appId: '1:123456789:android:dummyappidreplace',
    messagingSenderId: '123456789',
    projectId: 'family-calendar-app',
    storageBucket: 'family-calendar-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyIOSKeyReplace',
    appId: '1:123456789:ios:dummyappidreplace',
    messagingSenderId: '123456789',
    projectId: 'family-calendar-app',
    storageBucket: 'family-calendar-app.appspot.com',
    iosBundleId: 'com.example.familyCalendar',
  );
}
