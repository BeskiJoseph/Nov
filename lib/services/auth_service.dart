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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        // For web, suppress the deprecation warning
        // The warning is about using signIn() on web, but it still works
        // A future migration to google_identity_services with renderButton is recommended
        try {
          googleUser = await _googleSignInInstance.signInSilently();
        } catch (e) {
        }
        
        if (googleUser == null) {
          try {
            googleUser = await _googleSignInInstance.signIn();
          } catch (e) {
            // popup_closed is expected when user cancels
            if (e.toString().contains('popup_closed')) {
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
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignInInstance.signOut();
      await _auth.signOut();
    } catch (e) {
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
    }
  }

  // Update user profile
  static Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } on FirebaseAuthException catch (e) {
    }
  }

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print("Error sending email verification: $e");
      rethrow;
    }
  }

  // Reload user to get fresh data (like emailVerified status)
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print("Error reloading user: $e");
    }
  }
}
