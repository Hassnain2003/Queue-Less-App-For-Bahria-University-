import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const firebaseConfig = FirebaseOptions(
    apiKey: "AIzaSyB8Xa878TNDT6ugPgAcxuhGdXKvXOPiIeo",
    authDomain: "bahria-uni-queueless-app.firebaseapp.com",
    databaseURL: "https://bahria-uni-queueless-app-default-rtdb.firebaseio.com",
    projectId: "bahria-uni-queueless-app",
    storageBucket: "bahria-uni-queueless-app.firebasestorage.app",
    messagingSenderId: "342751547086",
    appId: "1:342751547086:web:b6a158d386ba635b19ca9f"
  );

  static Future<FirebaseApp> initializeFirebase() async {
    return await Firebase.initializeApp(options: firebaseConfig);
  }
}
