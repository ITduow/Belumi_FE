import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  RoleService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<void> ensureUserDocument({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final doc = _db.collection('users').doc(uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    await doc.set({
      'email': email,
      if (displayName != null && displayName.trim().isNotEmpty)
        'displayName': displayName.trim(),
    });
  }
}
