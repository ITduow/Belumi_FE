import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6EUqcE0cXD_IxwmAhi5x0tCpsN8DloN4',
    appId: '1:428023632321:web:a264c41ee90efecba2df40',
    messagingSenderId: '428023632321',
    projectId: 'belumi-1712f',
    authDomain: 'belumi-1712f.firebaseapp.com',
    storageBucket: 'belumi-1712f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0v8h6cOo3aegMskDsTQ8HGFqF2Q_-dE0',
    appId: '1:428023632321:android:8283ad1531898aeda2df40',
    messagingSenderId: '428023632321',
    projectId: 'belumi-1712f',
    storageBucket: 'belumi-1712f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6EUqcE0cXD_IxwmAhi5x0tCpsN8DloN4',
    appId: '1:428023632321:web:a264c41ee90efecba2df40',
    messagingSenderId: '428023632321',
    projectId: 'belumi-1712f',
    storageBucket: 'belumi-1712f.firebasestorage.app',
    iosBundleId: 'com.example.belumiApp',
  );
}
