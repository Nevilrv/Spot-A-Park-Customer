import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBXA7vkMfJ5QwcrgQmle35CSXrKr5Tgf20',
    appId: '1:380287931734:android:cbcb619a062bf570be72f7',
    messagingSenderId: '380287931734',
    projectId: 'spot-a-park-app',
    storageBucket: 'spot-a-park-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3Yr4fmUbpHpAiLgZi8bAN90DnWQbfo4o',
    appId: '1:380287931734:ios:b4ca4e14c89d6f5cbe72f7',
    messagingSenderId: '380287931734',
    projectId: 'spot-a-park-app',
    storageBucket: 'spot-a-park-app.appspot.com',
    iosClientId:
        '380287931734-jjc15qloeqauc18ls5pg7urhf5k9pthg.apps.googleusercontent.com',
    iosBundleId: 'com.sataware.spotapark',
  );
}
