import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static late GoogleSignIn _googleSignIn;
  
  // Initialize GoogleSignIn with platform-specific configuration
  static void _initializeGoogleSignIn() {
    if (kIsWeb) {
      // For web platform, pass clientId in configuration
      _googleSignIn = GoogleSignIn(
        clientId: '869861670780-64hg1hemqte17odvlu6r6gk3mikdbdps.apps.googleusercontent.com',
      );
    } else {
      // For mobile platforms, just create without clientId
      _googleSignIn = GoogleSignIn();
    }
  }
  
  // Ensure GoogleSignIn is initialized
  static GoogleSignIn get _googleSignInInstance {
    _initializeGoogleSignIn();
    return _googleSignIn;
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      print('Attempting to sign up: $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign up successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.code} - ${e.message}');
      // Return more specific error info
      rethrow;
    } catch (e) {
      print('Unexpected sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      print('Attempting sign in for: $email');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign in successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.code} - ${e.message}');
      // Return more specific error info
      rethrow;
    } catch (e) {
      print('Unexpected sign in error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('=== GOOGLE SIGN IN START ===');
      print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        // For web, suppress the deprecation warning
        // The warning is about using signIn() on web, but it still works
        // A future migration to google_identity_services with renderButton is recommended
        try {
          print('Attempting silent sign-in on web...');
          googleUser = await _googleSignInInstance.signInSilently();
        } catch (e) {
          print('Silent sign-in failed: $e');
        }
        
        if (googleUser == null) {
          print('Silent sign-in failed, attempting interactive sign-in...');
          try {
            googleUser = await _googleSignInInstance.signIn();
          } catch (e) {
            // popup_closed is expected when user cancels
            if (e.toString().contains('popup_closed')) {
              print('User cancelled Google Sign-In');
              return null;
            }
            rethrow;
          }
        }
      } else {
        // For mobile, use regular sign-in
        googleUser = await _googleSignInInstance.signIn();
      }
      
      if (googleUser == null) {
        print('Google sign in cancelled by user');
        return null;
      }

      print('Google user signed in: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Google auth tokens obtained');
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing into Firebase with Google credential');
      UserCredential result = await _auth.signInWithCredential(credential);
      print('Firebase sign in successful: ${result.user?.email}');
      print('=== GOOGLE SIGN IN SUCCESS ===');
      return result;
    } on FirebaseAuthException catch (e) {
      print('Firebase Google sign in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Google sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignInInstance.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Reset password error: ${e.message}');
    }
  }

  // Update user profile
  static Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } on FirebaseAuthException catch (e) {
      print('Update profile error: ${e.message}');
    }
  }

  // Debug method to check auth status
  static void debugAuthStatus() {
    final user = _auth.currentUser;
    print('Current user: ${user?.email}');
    print('Is logged in: ${user != null}');
    print('User ID: ${user?.uid}');
    print('Is email verified: ${user?.emailVerified}');
  }
}
