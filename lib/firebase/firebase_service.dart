import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> backupExpenses(Map<String, dynamic> expenses) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({'expenses': expenses});
      }
    } catch (e) {
      print('Error backing up expenses: $e');
    }
  }

  Future<Map<String, dynamic>?> restoreExpenses() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data()?['expenses'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error restoring expenses: $e');
    }
    return null;
  }
}
