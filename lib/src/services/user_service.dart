import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static Future<void> createUserDocumentIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    if (!(await doc.get()).exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
