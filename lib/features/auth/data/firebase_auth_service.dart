import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  Future<String> signInWithGoogleAndGetIdToken() async {
    _ensureFirebaseConfigured();

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final userCredential = await FirebaseAuth.instance.signInWithPopup(
        provider,
      );
      return _readIdToken(userCredential);
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    return _readIdToken(userCredential);
  }

  Future<String> _readIdToken(UserCredential userCredential) async {
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Could not read Firebase ID token.');
    }

    return idToken;
  }

  void _ensureFirebaseConfigured() {
    final options = Firebase.app().options;
    if (options.apiKey.startsWith('REPLACE_WITH') ||
        options.appId.startsWith('REPLACE_WITH') ||
        options.messagingSenderId.startsWith('REPLACE_WITH')) {
      throw Exception(
        'Firebase client config is still placeholder. Run flutterfire configure --project=belumi-1712f and replace lib/firebase_options.dart.',
      );
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await FirebaseAuth.instance.signOut();
  }
}
