import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // COMMENTED: Firebase Storage is paid, using local storage instead
// import 'package:firebase_messaging/firebase_messaging.dart'; // REMOVED

// Import generated Firebase options (will be created by FlutterFire CLI)
// Run: dart pub global run flutterfire_cli:flutterfire configure --project=orginize-app
import '../../firebase_options.dart';

/// Firebase Service
/// Handles Firebase initialization and provides access to Firebase services
///
/// NOTE: Firebase Storage is currently disabled (commented out) because:
/// - Firebase Storage is a paid service
/// - Planning to migrate to custom server storage in the future
/// - Currently using LocalStorageService for file/image storage
///
/// To re-enable Firebase Storage in the future:
/// 1. Uncomment the firebase_storage import above
/// 2. Uncomment the storage getter below
/// 3. Update pubspec.yaml if needed
class FirebaseService {
  static bool _isInitialized = false;

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // COMMENTED: Firebase Storage - Using LocalStorageService instead
  // static FirebaseStorage get storage => FirebaseStorage.instance;
  //
  // To use Firebase Storage in the future, uncomment the line above
  // and the import at the top of this file

  // static FirebaseMessaging get messaging => FirebaseMessaging.instance; // REMOVED

  static Future<void> initialize() async {
    try {
      // Initialize Firebase with generated options from FlutterFire CLI
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      // await _setupMessaging(); // REMOVED
    } catch (e) {
      print('Firebase initialization failed: $e');
      print(
          'Make sure you have run: dart pub global run flutterfire_cli:flutterfire configure --project=orginize-app');
      print('This will generate the required firebase_options.dart file');
      _isInitialized = false;
      rethrow; // Rethrow to make the error visible
    }
  }

  // _setupMessaging removed

  // Collections - with null safety for demo mode
  static CollectionReference get users {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized - running in demo mode');
    }
    return firestore.collection('users');
  }

  static CollectionReference get vendors {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized - running in demo mode');
    }
    return firestore.collection('vendors');
  }

  static CollectionReference get riders {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized - running in demo mode');
    }
    return firestore.collection('riders');
  }

  static CollectionReference get orders {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized - running in demo mode');
    }
    return firestore.collection('orders');
  }

  static CollectionReference get items {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized - running in demo mode');
    }
    return firestore.collection('items');
  }

  static bool get isInitialized => _isInitialized;
}
