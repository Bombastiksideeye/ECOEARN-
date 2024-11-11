import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WasteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Get user's waste collection stats
  Stream<Map<String, dynamic>> getWasteStats() {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return {
          'totalPoints': snapshot.data()?['totalPoints'] ?? 0,
          'totalItems': snapshot.data()?['totalItems'] ?? 0,
        };
      }
      return {'totalPoints': 0, 'totalItems': 0};
    });
  }

  // Initialize user stats if they don't exist
  Future<void> initializeUserStats() async {
    final docRef = _firestore.collection('users').doc(userId);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      await docRef.set({
        'totalPoints': 0,
        'totalItems': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
} 