import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthSession {
  const FirebaseAuthSession({
    required this.uid,
    required this.email,
    required this.idToken,
    this.displayName,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String idToken;
}

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth;

  final FirebaseAuth? _firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  Future<FirebaseAuthSession?> currentSession() async {
    _ensureFirebaseConfigured();
    final user = _auth.currentUser;
    return user == null ? null : _sessionFromUser(user);
  }

  Future<FirebaseAuthSession> signInWithGoogle() async {
    _ensureFirebaseConfigured();

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final credential = await _auth.signInWithPopup(provider);
      return _toSession(credential);
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _toSession(await _auth.signInWithCredential(credential));
  }

  Future<FirebaseAuthSession> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    _ensureFirebaseConfigured();
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toSession(credential);
  }

  Future<FirebaseAuthSession> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _ensureFirebaseConfigured();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(fullName);
    await credential.user?.reload();
    return _toCurrentSession();
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  Future<FirebaseAuthSession> _toSession(UserCredential credential) async {
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Firebase did not return a user.',
      );
    }
    return _sessionFromUser(user);
  }

  Future<FirebaseAuthSession> _toCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Firebase did not return a user.',
      );
    }
    return _sessionFromUser(user);
  }

  Future<FirebaseAuthSession> _sessionFromUser(User user) async {
    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Could not read Firebase ID token.',
      );
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Firebase account does not have an email.',
      );
    }

    return FirebaseAuthSession(
      uid: user.uid,
      email: email,
      displayName: user.displayName,
      idToken: idToken,
    );
  }

  void _ensureFirebaseConfigured() {
    final FirebaseOptions options;
    try {
      options = Firebase.app().options;
    } on FirebaseException catch (error) {
      throw FirebaseAuthException(
        code: error.code,
        message: error.message ?? 'Firebase is not initialized.',
      );
    }

    if (options.apiKey.startsWith('REPLACE_WITH') ||
        options.appId.startsWith('REPLACE_WITH') ||
        options.messagingSenderId.startsWith('REPLACE_WITH')) {
      throw FirebaseAuthException(
        code: 'firebase-placeholder-config',
        message:
            'Firebase client config is still placeholder. Run flutterfire configure --project=belumi-1712f and replace lib/firebase_options.dart.',
      );
    }
  }
}
