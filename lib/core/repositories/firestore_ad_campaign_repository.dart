import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/ad_campaign_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';

class FirestoreAdCampaignRepository implements IAdCampaignRepository {
  final FirebaseFirestore _firestore;

  FirestoreAdCampaignRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AdCampaign?> watchActiveCampaign(String residenceId) {
    if (residenceId.isEmpty) return Stream.value(null);
    // Les deux filtres (active + targetResidenceIds) doivent rester alignés
    // avec la règle Firestore (allow read: if resource.data.active == true)
    // - une requête de liste qui ne filtrerait pas elle-même sur "active"
    // serait entièrement refusée, Firestore ne pouvant pas garantir que
    // tous les résultats respectent la règle sans ce filtre côté requête.
    return _firestore
        .collection("adCampaigns")
        .where("active", isEqualTo: true)
        .where("targetResidenceIds", arrayContains: residenceId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : AdCampaign.fromMap(
                snapshot.docs.first.id, snapshot.docs.first.data()));
  }

  @override
  Future<Result<void>> recordImpression(String campaignId) async {
    try {
      await _firestore.collection("adCampaigns").doc(campaignId).update({
        "impressionCount": FieldValue.increment(1),
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> recordClick(String campaignId) async {
    try {
      await _firestore.collection("adCampaigns").doc(campaignId).update({
        "clickCount": FieldValue.increment(1),
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
