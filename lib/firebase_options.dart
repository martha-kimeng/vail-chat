// File generated manually from google-services.json.
// For iOS: register the app in the Firebase Console, download
// GoogleService-Info.plist, and update the iOS section below.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web – '
        'reconfigure with FlutterFire CLI.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Android ────────────────────────────────────────────────────────────────
  // Values sourced from android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVJ_I1BXzwmXk-qdJbAq1JLy6HRtCx8s4',
    appId: '1:663146321272:android:dff8e95523395d09be248d',
    messagingSenderId: '663146321272',
    projectId: 'vail-chat',
    storageBucket: 'vail-chat.firebasestorage.app',
  );

  // ── iOS ────────────────────────────────────────────────────────────────────
  // TODO: Register the iOS app in the Firebase Console, download
  // GoogleService-Info.plist, and replace the placeholder values below.
  // Fields to fill: apiKey, appId, iosBundleId (from Info.plist BUNDLE_ID).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '663146321272',
    projectId: 'vail-chat',
    storageBucket: 'vail-chat.firebasestorage.app',
    iosBundleId: 'com.vailchat.vailChat',
  );
}
