import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class BackupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  String? get userEmail => currentUser?.email;
  bool get isGoogleSignedIn =>
      currentUser?.providerData.any(
        (info) => info.providerId == 'google.com',
      ) ??
      false;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Backup data to Firebase
  Future<void> backupData(Map<String, dynamic> data) async {
    if (!isSignedIn) {
      throw Exception('Please sign in with Google to use online backup');
    }

    final userId = currentUser!.uid;
    final userEmail = currentUser!.email;

    await _firestore
        .collection('backups')
        .doc(userId)
        .collection('data')
        .doc('latest')
        .set({
          ...data,
          'lastBackup': FieldValue.serverTimestamp(),
          'userEmail': userEmail,
        });
  }

  // Restore data from Firebase
  Future<Map<String, dynamic>?> restoreData() async {
    if (!isSignedIn) {
      throw Exception(
        'Please sign in with Google to restore from online backup',
      );
    }

    final userId = currentUser!.uid;
    final doc = await _firestore
        .collection('backups')
        .doc(userId)
        .collection('data')
        .doc('latest')
        .get();

    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Get last backup date
  Future<DateTime?> getLastBackupDate() async {
    if (!isSignedIn) return null;

    final userId = currentUser!.uid;
    final doc = await _firestore
        .collection('backups')
        .doc(userId)
        .collection('data')
        .doc('latest')
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['lastBackup'] != null) {
        return (data['lastBackup'] as Timestamp).toDate();
      }
    }
    return null;
  }

  // Delete backup
  Future<void> deleteBackup() async {
    if (!isSignedIn) return;

    final userId = currentUser!.uid;
    await _firestore
        .collection('backups')
        .doc(userId)
        .collection('data')
        .doc('latest')
        .delete();
  }
}
