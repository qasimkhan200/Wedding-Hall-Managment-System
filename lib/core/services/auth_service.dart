import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'storage_service.dart';
import 'dart:io';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static bool get isSignedIn => _auth.currentUser != null;

  // Sign up with email and password
  static Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Wait a moment for Firebase to fully initialize the user
      await Future.delayed(const Duration(milliseconds: 500));

      // Role-based approval logic:
      // - Admin & Host: Auto-approved (isApproved = true)
      // - Vendor & Rider: Require admin approval (isApproved = false)
      final isApproved = (role == 'admin' || role == 'host');

      final user = UserModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        role: role,
        isActive: true,
        isApproved: isApproved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user data to Firestore
      await FirebaseService.users.doc(user.id).set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Sign up failed: $e';
    }
  }

  // Register Vendor with specialized data
  static Future<UserModel?> registerVendor({
    required String email,
    required String password,
    required String name, // Personal name
    required String phone,
    required String businessName,
    required String description,
    required String address,
    required List<String> categories,
    required File? cnicImage,
    required File? logoImage,
    required File? coverImage,
  }) async {
    try {
      // 1. Create Base User
      final user = await signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: 'vendor',
      );

      if (user == null) throw 'User creation failed';

      // 2. Upload Images
      String? cnicUrl;
      String? logoUrl;
      String? coverUrl;

      if (cnicImage != null) {
        cnicUrl = await StorageService.uploadIdentityDocument(
          file: cnicImage,
          userId: user.id,
          docType: 'cnic',
        );
      }

      if (logoImage != null) {
        logoUrl = await StorageService.uploadIdentityDocument(
          file: logoImage,
          userId: user.id,
          docType: 'logo',
        );
      }

      if (coverImage != null) {
        coverUrl = await StorageService.uploadIdentityDocument(
          file: coverImage,
          userId: user.id,
          docType: 'cover',
        );
      }

      // 3. Update User Doc with Vendor Fields
      await FirebaseService.users.doc(user.id).update({
        'businessName': businessName,
        'description': description,
        'address': address,
        'categories': categories,
        'cnicImage': cnicUrl,
        'logoImage': logoUrl,
        'coverImage': coverUrl,
        'subscriptionTier': 'free',
      });

      return user;
    } catch (e) {
      throw 'Vendor registration failed: $e';
    }
  }

  // Register Rider with specialized data
  static Future<UserModel?> registerRider({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
    required File? cnicImage,
    required File? licenseImage,
  }) async {
    try {
      // 1. Create Base User
      final user = await signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: 'rider',
      );
      if (user == null) throw 'User creation failed';

      // 2. Upload Images
      String? cnicUrl;
      String? licenseUrl;

      if (cnicImage != null) {
        cnicUrl = await StorageService.uploadIdentityDocument(
          file: cnicImage,
          userId: user.id,
          docType: 'cnic',
        );
      }
      if (licenseImage != null) {
        licenseUrl = await StorageService.uploadIdentityDocument(
          file: licenseImage,
          userId: user.id,
          docType: 'license',
        );
      }

      // 3. Update User Doc with Rider Fields
      // Note: RiderModel structure is flat in users collection too
      await FirebaseService.users.doc(user.id).update({
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'cnicImage': cnicUrl,
        'licenseImage': licenseUrl,
        'isAvailable': false,
        'totalDeliveries': 0,
        'rating': 0.0,
      });

      return user;
    } catch (e) {
      throw 'Rider registration failed: $e';
    }
  }

  // Sign in with email and password
  static Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      final userDoc =
          await FirebaseService.users.doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        throw 'User data not found';
      }

      return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>, userDoc.id);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Sign in failed: $e';
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user data
  static Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUserId == null) return null;

      final userDoc = await FirebaseService.users.doc(currentUserId).get();
      if (!userDoc.exists) return null;

      return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>, userDoc.id);
    } catch (e) {
      // Using debugPrint instead of print for production
      return null;
    }
  }

  // Update user profile
  static Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? profileImage,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (profileImage != null) updates['profileImage'] = profileImage;

      await FirebaseService.users.doc(userId).update(updates);
    } catch (e) {
      throw 'Profile update failed: $e';
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      // Validate email format
      if (email.isEmpty) {
        throw 'Please enter your email address';
      }
      if (!email.contains('@') || !email.contains('.')) {
        throw 'Please enter a valid email address';
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send reset email: $e';
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return e.message ?? 'Authentication error occurred';
    }
  }

  // Listen to auth state changes
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
