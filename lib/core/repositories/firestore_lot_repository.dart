import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/enum/add_tenant_outcome.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class FirestoreLotRepository implements ILotRepository {
  final FirebaseFirestore _firestore;

  FirestoreLotRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Lot>> _fetchLotsByUser(String userID) async {
    List<Lot> lots = [];
    // Une seule lecture de users/{uid}/lots, puis un accès direct par ID à
    // chaque résidence/lot concerné — plus de parcours de toutes les
    // résidences et tous leurs lots (O(nombre de lots de l'utilisateur)
    // au lieu de O(résidences × lots)).
    final userLotsSnapshot =
        await _firestore.collection("users").doc(userID).collection("lots").get();

    for (final userLotDoc in userLotsSnapshot.docs) {
      final userLotData = userLotDoc.data();
      final String? residenceId = userLotData['residenceId'];
      final String lotId = userLotDoc.id;

      if (residenceId == null) continue;

      final residenceSnapshot =
          await _firestore.collection("residences").doc(residenceId).get();
      final lotSnapshot = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("lots")
          .doc(lotId)
          .get();

      if (!residenceSnapshot.exists || !lotSnapshot.exists) continue;

      Lot lot = Lot.fromMap(lotSnapshot.data()!);
      lot.residenceData = residenceSnapshot.data() ?? {};
      lot.residenceId = residenceId;
      // colorSelected/nameLot sont déjà dans le doc User/lots, pas besoin
      // d'un second aller-retour vers getLotDetails.
      lot.userLotDetails = {
        "colorSelected": userLotData['colorSelected'],
        "nameLot": userLotData['nameLot'],
        "isApprovedLot": userLotData['isApprovedLot'] ?? false,
      };

      lots.add(lot);
    }

    return lots;
  }

  @override
  Future<Result<List<Lot>>> getLotByIdUser(String numUser) async {
    try {
      return Result.success(await _fetchLotsByUser(numUser));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Lot>> getFirstLotByUserId(String numUser) async {
    try {
      final lots = await _fetchLotsByUser(numUser);
      if (lots.isNotEmpty) {
        return Result.success(lots.first);
      }
      return Result.failure(
          NotFoundException("Aucun lot trouvé pour l'utilisateur $numUser"));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Lot>>> getLotByResidence(String residenceId) async {
    List<Lot> lots = [];
    try {
      final querySnapshot = await _firestore
          .collection("residences")
          .where("id", isEqualTo: residenceId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final residenceDoc = querySnapshot.docs.first;
        final lotQuerySnapshot =
            await residenceDoc.reference.collection("lots").get();

        for (var lotDoc in lotQuerySnapshot.docs) {
          lots.add(Lot.fromMap(lotDoc.data()));
        }
      }
      return Result.success(lots);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Lot?>> getUniqueLot(
      String residenceId, String bat, String numlot) async {
    try {
      final querySnapshot = await _firestore
          .collection("residences")
          .where("id", isEqualTo: residenceId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final residenceDoc = querySnapshot.docs.first;

        final lotQuerySnapshot = await residenceDoc.reference
            .collection("lots")
            .where("batiment", isEqualTo: bat)
            .where("lot", isEqualTo: numlot)
            .get();

        if (lotQuerySnapshot.docs.isNotEmpty) {
          return Result.success(Lot.fromMap(lotQuerySnapshot.docs.first.data()));
        }
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<int>> countLocatairesExcludingUser(String numUser) async {
    try {
      final lots = await _fetchLotsByUser(numUser);

      int count = 0;
      for (Lot lot in lots) {
        dynamic idLocataire = lot.idLocataire;

        if (idLocataire is List) {
          count += idLocataire.where((id) => id != numUser).length;
        } else if (idLocataire is String && idLocataire != numUser) {
          count++;
        }
      }
      return Result.success(count);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> updateLotColor(
      String userUid, String id, Color newColor) async {
    try {
      final lotRef =
          _firestore.collection("users").doc(userUid).collection("lots").doc(id);

      final hexColor =
          newColor.toARGB32().toRadixString(16).padLeft(8, '0');

      await lotRef.update({'colorSelected': hexColor});
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> updateNameLot(
      String userUid, String id, String newName) async {
    try {
      final lotRef =
          _firestore.collection("users").doc(userUid).collection("lots").doc(id);

      await lotRef.update({'nameLot': newName});
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<bool>> updateLot(
      String residenceId, String idLot, String field, dynamic upDate) async {
    try {
      final lotRef = _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("lots")
          .doc(idLot);

      final snapshot = await lotRef.get();

      if (snapshot.exists) {
        await lotRef.update({field: upDate});
        return const Result.success(true);
      }
      return const Result.success(false);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  // Applique la décision de remplacement ou d'ajout de locataire au lot.
  // N'écrit QUE sur residences/{id}/lots/{lotId} (idLocataire), seul champ
  // qu'un propriétaire non CS member a le droit de modifier - cf.
  // firestore.rules. Comme pour _removeIdLocataireInternal (retrait), la
  // création de users/{tenantId}/lots/{lotId} et le recalcul de
  // residencesIds/sharedWithLandlords sont entièrement délégués à la Cloud
  // Function sync_lot_tenants (functions_python/main.py), déclenchée par
  // cette écriture avec les privilèges Admin : un propriétaire n'a pas le
  // droit d'écrire directement sur le document User d'un tiers (d'où le
  // PermissionDeniedException si on tentait addLotToUser/
  // _recomputeSharedWithLandlords ici).
  Future<void> _applyTenantChange(DocumentReference lotRef, String residenceId,
      String idLot, String tenantId, bool replace) async {
    if (replace) {
      await lotRef.update({
        'idLocataire': [tenantId]
      });
    } else {
      await lotRef.update({
        'idLocataire': FieldValue.arrayUnion([tenantId])
      });
    }
  }

  // Reconstruit entièrement users/{tenantId}.sharedWithLandlords à partir des
  // lots où tenantId est effectivement dans idLocataire, plutôt qu'un
  // arrayUnion/Remove incrémental : évite les incohérences si un même
  // propriétaire partage plusieurs lots avec ce locataire.
  Future<void> _recomputeSharedWithLandlords(String tenantId) async {
    final lots = await _fetchLotsByUser(tenantId);
    final Set<String> landlordUids = {};

    for (final lot in lots) {
      final isTenantHere = lot.idLocataire?.contains(tenantId) ?? false;
      if (isTenantHere && lot.idProprietaire != null) {
        landlordUids.addAll(lot.idProprietaire!);
      }
    }

    await _firestore.collection("users").doc(tenantId).set({
      "sharedWithLandlords": landlordUids.toList(),
    }, SetOptions(merge: true));
  }

  // Reconstruit entièrement users/{userId}.residencesIds à partir de
  // users/{userId}/lots, pour rester cohérent avec firestore.rules après un
  // retrait de lot (voir removeIdLocataire / removeIdProprietaire /
  // removeUserFromAllLots).
  Future<void> _recomputeResidencesIds(String userId) async {
    final userLotsSnapshot =
        await _firestore.collection("users").doc(userId).collection("lots").get();

    final residenceIds = userLotsSnapshot.docs
        .map((doc) => doc.data()['residenceId'] as String?)
        .whereType<String>()
        .toSet();

    await _firestore.collection("users").doc(userId).set({
      "residencesIds": residenceIds.toList(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Result<AddTenantOutcome>> addTenant(
      String residenceId, String idLot, String tenantId,
      {bool? replace}) async {
    try {
      final lotRef = _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("lots")
          .doc(idLot);

      final lotDoc = await lotRef.get();

      if (!lotDoc.exists) {
        return const Result.success(AddTenantOutcome.alreadyPresent);
      }

      // lotDoc.get('idLocataire') lève une StateError ("Bad state: field
      // does not exist") si le champ est absent du document (lot jamais
      // occupé) plutôt que de renvoyer null - data()?[...] est sans risque.
      final currentLocataires =
          List<dynamic>.from(lotDoc.data()?['idLocataire'] ?? []);

      if (currentLocataires.contains(tenantId)) {
        return const Result.success(AddTenantOutcome.alreadyPresent);
      }

      if (currentLocataires.isNotEmpty) {
        if (replace == null) {
          // Aucune écriture : l'appelant doit d'abord demander à
          // l'utilisateur de trancher, puis rappeler avec replace renseigné.
          return const Result.success(
              AddTenantOutcome.needsReplaceOrAddDecision);
        }
        await _applyTenantChange(
            lotRef, residenceId, idLot, tenantId, replace);
        return const Result.success(AddTenantOutcome.added);
      } else {
        await _applyTenantChange(lotRef, residenceId, idLot, tenantId, false);
        return const Result.success(AddTenantOutcome.added);
      }
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removeUserFromAllLots(String userID) async {
    try {
      final lots = await _fetchLotsByUser(userID);

      for (Lot lot in lots) {
        if (lot.idLocataire != null && lot.idLocataire!.contains(userID)) {
          await _removeIdLocataireInternal(lot.residenceId, lot.id!, userID);
        }

        if (lot.idProprietaire != null &&
            lot.idProprietaire!.contains(userID)) {
          await _removeIdProprietaireInternal(
              lot.residenceId, lot.id!, userID);
        }
      }

      // Dénormalisé pour firestore.rules : residencesIds doit refléter les
      // lots restants de l'utilisateur une fois les retraits ci-dessus faits
      // (sharedWithLandlords est déjà recalculé par removeIdLocataire).
      await _recomputeResidencesIds(userID);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  Future<void> _removeIdLocataireInternal(
      String residenceId, String idLot, String idLocataireToRemove) async {
    final lotRef = _firestore
        .collection("residences")
        .doc(residenceId)
        .collection("lots")
        .doc(idLot);

    final lotSnapshot = await lotRef.get();

    if (lotSnapshot.exists) {
      final lotData = lotSnapshot.data() as Map<String, dynamic>;
      final idLocataires = List.from(lotData['idLocataire'] ?? []);
      if (idLocataires.contains(idLocataireToRemove)) {
        idLocataires.remove(idLocataireToRemove);
        // Seuls idLocataire/idLocataireOld sont modifiables ici par un
        // simple propriétaire (non CS member) - cf. firestore.rules. Le
        // nettoyage côté locataire (sa référence à ce lot dans
        // users/{uid}/lots, residencesIds, sharedWithLandlords) est fait
        // côté serveur par la Cloud Function sync_lot_tenant_removal
        // (functions_python/main.py), déclenchée par cette écriture : un
        // propriétaire n'a pas le droit d'écrire directement sur le
        // document User d'un tiers.
        await lotRef.update({
          'idLocataire': idLocataires,
          // Historique (onglet "Historique" de ManagementTenant) : une
          // entrée horodatée par révocation, jamais réécrite.
          'idLocataireOld': FieldValue.arrayUnion([
            {'uid': idLocataireToRemove, 'leftAt': Timestamp.now()}
          ]),
        });
      }
    }
  }

  @override
  Future<Result<void>> removeIdLocataire(
      String residenceId, String idLot, String idLocataireToRemove) async {
    try {
      await _removeIdLocataireInternal(residenceId, idLot, idLocataireToRemove);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  Future<void> _removeIdProprietaireInternal(
      String residenceId, String idLot, String idProprietaireToRemove) async {
    final lotRef = _firestore
        .collection("residences")
        .doc(residenceId)
        .collection("lots")
        .doc(idLot);

    final lotSnapshot = await lotRef.get();

    if (lotSnapshot.exists) {
      final lotData = lotSnapshot.data() as Map<String, dynamic>;
      final idProprietaires = List.from(lotData['idProprietaire'] ?? []);
      idProprietaires.remove(idProprietaireToRemove);
      await lotRef.update({'idProprietaire': idProprietaires});

      // Dénormalisé pour firestore.rules : les locataires actuels de ce lot
      // ne doivent plus voir ce propriétaire dans sharedWithLandlords.
      final idLocataires = List<String>.from(lotData['idLocataire'] ?? []);
      for (final tenantId in idLocataires) {
        await _recomputeSharedWithLandlords(tenantId);
      }
    }
  }

  @override
  Future<Result<void>> removeIdProprietaire(
      String residenceId, String idLot, String idProprietaireToRemove) async {
    try {
      await _removeIdProprietaireInternal(
          residenceId, idLot, idProprietaireToRemove);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> createOrUpdateLot(String residenceId, Lot lot) async {
    try {
      final lotRef =
          _firestore.collection("residences").doc(residenceId).collection("lots");

      // Défense contre un ID corrompu par des espaces parasites (déjà vu en
      // production : un ID Firestore avec un espace en préfixe crée un
      // document fantôme distinct du vrai). Un ID uniquement fait d'espaces
      // devient vide et retombe donc sur la branche création.
      final String? trimmedId = lot.id?.trim();

      // Un nouveau lot n'a pas encore d'ID (lot.id == null) : on ne peut pas
      // s'en servir pour interroger Firestore (where("id", isEqualTo: null)
      // peut matcher n'importe quel vieux document dont le champ id est
      // absent, et écraser un lot existant sans rapport). On décide donc
      // créer/mettre à jour directement en Dart, jamais via une requête sur
      // un id potentiellement null.
      if (trimmedId == null || trimmedId.isEmpty) {
        final newDocRef = await lotRef.add(lot.toJsonForDb());
        await newDocRef.update({'id': newDocRef.id});
        // Synchronise l'ID généré sur l'objet local : sans ça, un second
        // enregistrement dans la même session le traiterait de nouveau
        // comme un nouveau lot (id encore null) et reproduirait le bug.
        lot.id = newDocRef.id;
      } else {
        lot.id = trimmedId;
        // set(merge: true) plutôt que update() : reste robuste si l'ID
        // local ne correspond plus à un document existant (état de l'app
        // conservé après un hot reload, document supprimé entre-temps...)
        // au lieu de planter avec cloud_firestore/not-found.
        await lotRef
            .doc(trimmedId)
            .set(lot.toJsonForDb(), SetOptions(merge: true));
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> deleteLot(String residenceId, String idLot) async {
    try {
      final lotRef =
          _firestore.collection("residences").doc(residenceId).collection("lots");

      final query = await lotRef.where("id", isEqualTo: idLot).limit(1).get();

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await lotRef.doc(docId).delete();
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
