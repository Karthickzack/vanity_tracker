import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] configured with your live Firebase Project: vanity-tracker.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAc5zVgaCK3CRcjsXeVTMPvJ6ToY4i7pXY',
    appId: '1:999868479138:web:6f0f0f00cfc6ca5abec9fb',
    messagingSenderId: '999868479138',
    projectId: 'vanity-tracker',
    authDomain: 'vanity-tracker.firebaseapp.com',
    storageBucket: 'vanity-tracker.firebasestorage.app',
    measurementId: 'G-GNYJ9BWYNV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAc5zVgaCK3CRcjsXeVTMPvJ6ToY4i7pXY',
    appId: '1:999868479138:web:6f0f0f00cfc6ca5abec9fb',
    messagingSenderId: '999868479138',
    projectId: 'vanity-tracker',
    storageBucket: 'vanity-tracker.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAc5zVgaCK3CRcjsXeVTMPvJ6ToY4i7pXY',
    appId: '1:999868479138:web:6f0f0f00cfc6ca5abec9fb',
    messagingSenderId: '999868479138',
    projectId: 'vanity-tracker',
    storageBucket: 'vanity-tracker.firebasestorage.app',
    iosBundleId: 'com.vanitytracker.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAc5zVgaCK3CRcjsXeVTMPvJ6ToY4i7pXY',
    appId: '1:999868479138:web:6f0f0f00cfc6ca5abec9fb',
    messagingSenderId: '999868479138',
    projectId: 'vanity-tracker',
    storageBucket: 'vanity-tracker.firebasestorage.app',
    iosBundleId: 'com.vanitytracker.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAc5zVgaCK3CRcjsXeVTMPvJ6ToY4i7pXY',
    appId: '1:999868479138:web:6f0f0f00cfc6ca5abec9fb',
    messagingSenderId: '999868479138',
    projectId: 'vanity-tracker',
    authDomain: 'vanity-tracker.firebaseapp.com',
    storageBucket: 'vanity-tracker.firebasestorage.app',
    measurementId: 'G-GNYJ9BWYNV',
  );
}
