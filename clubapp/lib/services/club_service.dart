import 'package:cloud_firestore/cloud_firestore.dart';

class ClubService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Checks if a student is authorized to manage a specific club.
  Future<Map<String, dynamic>?> getClubForPresident(String userEmail) async {
    try {
      final snapshot = await _db
          .collection('clubs')
          .where('presidents', arrayContains: userEmail.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return data;
      }
    } catch (e) {
      print('Error checking president status: $e');
    }
    return null;
  }


  /// Updates the club banner using a direct URL (Free alternative)
  Future<void> updateClubBannerUrl(String clubId, String url) async {
    await _db.collection('clubs').doc(clubId).update({
      'bannerUrl': url,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the keywords used to match this club to events
  Future<void> updateClubKeywords(String clubId, List<String> keywords) async {
    await _db.collection('clubs').doc(clubId).update({
      'keywords': keywords.map((k) => k.trim()).toList(),
    });
  }

  /// Listen to a single club's data
  Stream<Map<String, dynamic>?> getClubStream(String clubId) {
    return _db.collection('clubs').doc(clubId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    });
  }

  /// Listen to all clubs to perform keyword matching in the UI
  Stream<List<Map<String, dynamic>>> getClubsStream() {
    return _db.collection('clubs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
