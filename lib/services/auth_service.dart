import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // -------------------------------------------------------------
  // EMAIL & PASSWORD AUTHENTICATION
  // -------------------------------------------------------------

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (fullName != null && fullName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(fullName.trim());
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    }
  }

  // -------------------------------------------------------------
  // GOOGLE SIGN-IN
  // -------------------------------------------------------------

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User aborted the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // -------------------------------------------------------------
  // APPLE SIGN-IN
  // -------------------------------------------------------------

  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Save user's display name if provided (Apple only returns this on FIRST login)
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        final name =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        if (name.isNotEmpty) {
          await userCredential.user?.updateDisplayName(name);
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  // -------------------------------------------------------------
  // FACEBOOK SIGN-IN
  // -------------------------------------------------------------

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result;
      String? rawNonce;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        result = await FacebookAuth.instance.login(
          permissions: ['public_profile', 'email'],
          loginTracking: LoginTracking.limited,
          nonce: nonce,
        );
      } else {
        result = await FacebookAuth.instance.login(
          permissions: ['public_profile', 'email'],
        );
      }

      if (result.status == LoginStatus.success) {
        final AuthCredential credential;
        if (defaultTargetPlatform == TargetPlatform.iOS && rawNonce != null) {
          credential = OAuthProvider('facebook.com').credential(
            idToken: result.accessToken!.tokenString,
            rawNonce: rawNonce,
          );
        } else {
          credential = FacebookAuthProvider.credential(
            result.accessToken!.tokenString,
          );
        }
        return await _auth.signInWithCredential(credential);
      } else if (result.status == LoginStatus.cancelled) {
        return null; // User cancelled
      } else {
        throw Exception(result.message ?? 'Facebook sign in error');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception('Facebook Sign-In failed: $e');
    }
  }

  // -------------------------------------------------------------
  // TWITTER (X) SIGN-IN
  // -------------------------------------------------------------

  Future<UserCredential?> signInWithTwitter() async {
    try {
      final twitterProvider = TwitterAuthProvider();
      return await _auth.signInWithProvider(twitterProvider);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception('Twitter Sign-In failed: $e');
    }
  }

  // -------------------------------------------------------------
  // PASSWORD RESET
  // -------------------------------------------------------------

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    }
  }

  // -------------------------------------------------------------
  // SIGN OUT
  // -------------------------------------------------------------

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        GoogleSignIn().signOut(),
        FacebookAuth.instance.logOut(),
      ]);
    } catch (_) {
      // Best-effort sign out
      await _auth.signOut();
    }
  }

  // -------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email using a different sign-in method.';
      case 'invalid-credential':
        return 'The credentials provided are invalid or expired.';
      case 'operation-not-allowed':
        return 'This sign-in provider is not enabled in the Firebase Console.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
