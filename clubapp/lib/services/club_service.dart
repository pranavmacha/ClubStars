import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../utils/app_logger.dart';

/// Service for handling club-related operations
class ClubService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if a student is authorized to manage a specific club.
  Future<Map<String, dynamic>?> getClubForPresident(String userEmail) async {
    try {
      AppLogger.i('Checking president status for: $userEmail');
      final snapshot = await _db
          .collection(AppConstants.clubsCollection)
          .where('presidents', arrayContains: userEmail.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        AppLogger.v('President found for club');
        return data;
      }
      AppLogger.v('No president role found for user');
      return null;
    } catch (e) {
      AppLogger.e('Error checking president status', e);
      return null;
    }
  }

  /// Updates the club banner using a direct URL (Free alternative)
  Future<void> updateClubBannerUrl(String clubId, String url) async {
    try {
      AppLogger.i('Updating club banner for: $clubId');
      await _db.collection(AppConstants.clubsCollection).doc(clubId).update({
        'bannerUrl': url,
        'last_updated': FieldValue.serverTimestamp(),
      });
      AppLogger.v('Club banner updated successfully');
    } catch (e) {
      AppLogger.e('Failed to update club banner', e);
      rethrow;
    }
  }

  /// Updates the authorized presidents for a club
  Future<void> updateClubPresidents(String clubId, List<String> emails) async {
    try {
      AppLogger.i('Updating presidents for club: $clubId');
      await _db.collection(AppConstants.clubsCollection).doc(clubId).update({
        'presidents': emails.map((e) => e.trim().toLowerCase()).toList(),
      });
      AppLogger.v('Club presidents updated successfully');
    } catch (e) {
      AppLogger.e('Failed to update club presidents', e);
      rethrow;
    }
  }

  /// Updates the keywords used to match this club to events
  Future<void> updateClubKeywords(String clubId, List<String> keywords) async {
    try {
      AppLogger.i('Updating keywords for club: $clubId');
      await _db.collection(AppConstants.clubsCollection).doc(clubId).update({
        'keywords': keywords.map((k) => k.trim()).toList(),
      });
      AppLogger.v('Club keywords updated successfully');
    } catch (e) {
      AppLogger.e('Failed to update club keywords', e);
      rethrow;
    }
  }

  /// Listen to a single club's data
  Stream<Map<String, dynamic>?> getClubStream(String clubId) {
    AppLogger.v('Listening to club: $clubId');
    return _db
        .collection(AppConstants.clubsCollection)
        .doc(clubId)
        .snapshots()
        .map((doc) {
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
    AppLogger.v('Listening to all clubs');
    return _db.collection(AppConstants.clubsCollection).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
