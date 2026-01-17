// File generated manually (fixed for Android + Web)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

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
    apiKey: 'AIzaSyBn2HELvH_JGtJiwMBzHlwHUi4mUdgBALY',
    appId: '1:499444899185:android:699515a11312e79791ead0',
    messagingSenderId: '499444899185',
    projectId: 'legalease-91e62',
    storageBucket: 'legalease-91e62.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCxhRY0XtYVq2Up6SXqnkY3L2kCiKTp63A',
    appId: '1:499444899185:web:41f6bac70fef0be691ead0',
    messagingSenderId: '499444899185',
    projectId: 'legalease-91e62',
    authDomain: 'legalease-91e62.firebaseapp.com',
    storageBucket: 'legalease-91e62.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzeLktt3c_op4UPYXYu9d40MKAaEWTUBM',
    appId: '1:499444899185:ios:8216b7f81fbda24e91ead0',
    messagingSenderId: '499444899185',
    projectId: 'legalease-91e62',
    storageBucket: 'legalease-91e62.firebasestorage.app',
    iosBundleId: 'com.example.legalEase',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCxhRY0XtYVq2Up6SXqnkY3L2kCiKTp63A',
    appId: '1:499444899185:web:de678ec0368e173091ead0',
    messagingSenderId: '499444899185',
    projectId: 'legalease-91e62',
    authDomain: 'legalease-91e62.firebaseapp.com',
    storageBucket: 'legalease-91e62.firebasestorage.app',
  );
}