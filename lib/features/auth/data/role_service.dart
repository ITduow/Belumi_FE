import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  RoleService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<String?> getRole(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    final role = snapshot.data()?['role'];
    return role is String ? role.toLowerCase() : null;
  }

  Future<void> ensureUserDocument({
    required String uid,
    required String email,
    String role = 'user',
  }) async {
    final doc = _db.collection('users').doc(uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    await doc.set({'email': email, 'role': role});
  }
}
