import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String databaseUrl =
      'https://app1-8687c-default-rtdb.firebaseio.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1NL-5avcw0IToj7yURkgrjSbqfZzMRvE',
    appId: '1:508453702237:android:9c6578cd993ab573885bb4',
    messagingSenderId: '508453702237',
    projectId: 'app1-8687c',
    databaseURL: databaseUrl,
    storageBucket: 'app1-8687c.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAey_-o7i9DDMaB5LLoPR-lCNwvp15rMzA',
    appId: '1:508453702237:ios:0ad920d6b43ed736885bb4',
    messagingSenderId: '508453702237',
    projectId: 'app1-8687c',
    databaseURL: databaseUrl,
    storageBucket: 'app1-8687c.firebasestorage.app',
    iosBundleId: 'com.koshy.carrent.carrent',
  );
}
