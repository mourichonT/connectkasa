import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/ad_campaign_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';
import 'package:konodal/models/pages_models/ad_campaign_config.dart';

class FirestoreAdCampaignRepository implements IAdCampaignRepository {
  final FirebaseFirestore _firestore;

  FirestoreAdCampaignRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<AdCampaign>> watchActiveCampaigns(String residenceId) {
    if (residenceId.isEmpty) return Stream.value(const []);
    // Les deux filtres (active + targetResidenceIds) doivent rester alignés
    // avec la règle Firestore (allow read: if resource.data.active == true)
    // - une requête de liste qui ne filtrerait pas elle-même sur "active"
    // serait entièrement refusée, Firestore ne pouvant pas garantir que
    // tous les résultats respectent la règle sans ce filtre côté requête.
    return _firestore
        .collection("adCampaigns")
        .where("active", isEqualTo: true)
        .where("targetResidenceIds", arrayContains: residenceId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdCampaign.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<AdCampaignConfig> watchConfig() {
    // Doc absent -> fréquence 0 (aucune pub insérée), cohérent avec le
    // comportement actuel de Homeview quand `campaigns` est vide.
    return _firestore.doc("config/adCampaigns").snapshots().map(
        (snapshot) => AdCampaignConfig.fromMap(snapshot.data()));
  }

  @override
  Future<Result<void>> recordImpression(
      String campaignId, String residenceId, String uid, String statutResident) async {
    try {
      final campaignRef = _firestore.collection("adCampaigns").doc(campaignId);
      final batch = _firestore.batch();
      batch.update(campaignRef, {
        "impressionCount": FieldValue.increment(1),
        "impressionsByResidence.$residenceId": FieldValue.increment(1),
      });
      batch.set(campaignRef.collection("impressions").doc(), {
        "uid": uid,
        "residenceId": residenceId,
        "statutResident": statutResident,
        "timestamp": FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> recordClick(
      String campaignId, String residenceId, String uid, String statutResident) async {
    try {
      final campaignRef = _firestore.collection("adCampaigns").doc(campaignId);
      final batch = _firestore.batch();
      batch.update(campaignRef, {
        "clickCount": FieldValue.increment(1),
        "clicksByResidence.$residenceId": FieldValue.increment(1),
      });
      batch.set(campaignRef.collection("clicks").doc(), {
        "uid": uid,
        "residenceId": residenceId,
        "statutResident": statutResident,
        "timestamp": FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
