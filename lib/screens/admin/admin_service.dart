import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getRecyclingRequests() {
    return _firestore
        .collection('recycling_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> approveRequest(String requestId, String userId, double weight) async {
    final points = (weight * 10).round();
    
    // Use a batch to ensure all operations succeed or fail together
    final batch = _firestore.batch();

    // Update request status
    final requestRef = _firestore.collection('recycling_requests').doc(requestId);
    batch.update(requestRef, {
      'status': 'approved',
      'pointsAwarded': points,
      'approvedAt': FieldValue.serverTimestamp(),
    });

    // Update user's points
    final userRef = _firestore.collection('users').doc(userId);
    batch.set(userRef, {
      'totalPoints': FieldValue.increment(points),
      'totalItems': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Commit the batch
    await batch.commit();
  }
}
