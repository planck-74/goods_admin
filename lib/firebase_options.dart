import 'package:firebase_core/firebase_core.dart';
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwmoR8ocO6rXPuxwyU0yOQZmc_a0Nd3H4',
    appId: '1:267612126842:android:172d2d2c0ac8d879fbc5c3',
    messagingSenderId: '267612126842',
    projectId: 'goods-for-exchange',
    databaseURL: 'https://goods-for-exchange-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'goods-for-exchange.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtyMm6CnG7s_6y633dXqO6nrAZgfFJ-zQ',
    appId: '1:267612126842:web:e5759ce08be62ee7fbc5c3',
    messagingSenderId: '267612126842',
    projectId: 'goods-for-exchange',
    authDomain: 'goods-for-exchange.firebaseapp.com',
    databaseURL: 'https://goods-for-exchange-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'goods-for-exchange.appspot.com',
    measurementId: 'G-FBVKZ0KZBS',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB6V204AdKsisTW7J4lxqTo62l_KJ5eiJw',
    appId: '1:267612126842:ios:e852c817a2979fb8fbc5c3',
    messagingSenderId: '267612126842',
    projectId: 'goods-for-exchange',
    databaseURL: 'https://goods-for-exchange-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'goods-for-exchange.appspot.com',
    iosBundleId: 'com.example.goodsAdmin',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB6V204AdKsisTW7J4lxqTo62l_KJ5eiJw',
    appId: '1:267612126842:ios:f9036ae887acae52fbc5c3',
    messagingSenderId: '267612126842',
    projectId: 'goods-for-exchange',
    databaseURL: 'https://goods-for-exchange-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'goods-for-exchange.appspot.com',
    iosBundleId: 'com.planck.goodsadmins',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBtyMm6CnG7s_6y633dXqO6nrAZgfFJ-zQ',
    appId: '1:267612126842:web:9189bbda9464f485fbc5c3',
    messagingSenderId: '267612126842',
    projectId: 'goods-for-exchange',
    authDomain: 'goods-for-exchange.firebaseapp.com',
    databaseURL: 'https://goods-for-exchange-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'goods-for-exchange.appspot.com',
    measurementId: 'G-0G81JFWTDW',
  );

}