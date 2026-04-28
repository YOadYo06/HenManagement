import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAsxB_QJGL661Ao0CZKdtiVyKxFjhmTtl0',
    appId: '1:583597898110:web:525f60c0d9aec3e9599b2f',
    messagingSenderId: '583597898110',
    projectId: 'smart-study-desk-monitor',
    authDomain: 'smart-study-desk-monitor.firebaseapp.com',
    databaseURL:
        'https://smart-study-desk-monitor-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'smart-study-desk-monitor.firebasestorage.app',
    measurementId: 'G-KKQBSZ83BE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvCplUk0WNmmRB4ITqUxken5dWRw1FgxU',
    appId: '1:583597898110:android:c9e407989b7728b4599b2f',
    messagingSenderId: '583597898110',
    projectId: 'smart-study-desk-monitor',
    databaseURL:
        'https://smart-study-desk-monitor-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'smart-study-desk-monitor.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBh9ulI-BX1d8bfjVUW-PyajQmi47Ajl_0',
    appId: '1:583597898110:ios:41eec8fb795ee977599b2f',
    messagingSenderId: '583597898110',
    projectId: 'smart-study-desk-monitor',
    databaseURL:
        'https://smart-study-desk-monitor-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'smart-study-desk-monitor.firebasestorage.app',
    iosBundleId: 'com.example.envReading',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAsxB_QJGL661Ao0CZKdtiVyKxFjhmTtl0',
    appId: '1:583597898110:web:3ad9f768d65fa120599b2f',
    messagingSenderId: '583597898110',
    projectId: 'smart-study-desk-monitor',
    authDomain: 'smart-study-desk-monitor.firebaseapp.com',
    databaseURL:
        'https://smart-study-desk-monitor-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'smart-study-desk-monitor.firebasestorage.app',
    measurementId: 'G-6QYCVVEQ1T',
  );

  static const FirebaseOptions linux = web;
}
