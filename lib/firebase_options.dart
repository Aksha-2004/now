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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDXw8kUe2EUQx3JHmynaJAmbV7emOqAx18",
    authDomain: "disaster-response-and-safety.firebaseapp.com",
    projectId: "disaster-response-and-safety",
    storageBucket: "disaster-response-and-safety.firebasestorage.app",
    messagingSenderId: "402196562208",
    appId: "1:402196562208:web:da30a2225a04c27604d745",
    measurementId: null,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDXw8kUe2EUQx3JHmynaJAmbV7emOqAx18",
    appId: "1:402196562208:web:da30a2225a04c27604d745",
    messagingSenderId: "402196562208",
    projectId: "disaster-response-and-safety",
    storageBucket: "disaster-response-and-safety.firebasestorage.app",
  );
}
