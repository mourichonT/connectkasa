import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/residence_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/models/pages_models/structure_residence.dart';

class FirestoreResidenceRepository implements IResidenceRepository {
  final FirebaseFirestore _firestore;

  FirestoreResidenceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<List<Residence>>> rechercheFirestore(String saisie) async {
    try {
      final querySnapshot = await _firestore.collection("residences").get();
      final residencesTrouvees = <Residence>[];

      for (var doc in querySnapshot.docs) {
        final residence =
            Residence.fromJson(doc.data());

        if ((residence.name.toLowerCase().contains(saisie.toLowerCase())) ||
            (residence.street.toLowerCase().contains(saisie.toLowerCase())) ||
            (residence.city.toLowerCase().contains(saisie.toLowerCase())) ||
            (residence.zipCode
                .toLowerCase()
                .contains(saisie.toLowerCase()))) {
          residencesTrouvees.add(residence);
        }
      }

      return Result.success(residencesTrouvees);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Residence>> getResidenceByRef(String residenceId) async {
    try {
      final docSnapshot =
          await _firestore.collection("residences").doc(residenceId).get();

      if (!docSnapshot.exists) {
        return Result.failure(
            NotFoundException("Résidence non trouvée pour l'id $residenceId"));
      }

      final residence =
          await Residence.fromFirestoreWithStructures(docSnapshot, null);
      return Result.success(residence);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<bool>> updateResidence(
      String refResidence, Map<String, dynamic> updatedData) async {
    try {
      final docRef = _firestore.collection("residences").doc(refResidence);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        await docRef.update(updatedData);
        return const Result.success(true);
      } else {
        return const Result.success(false);
      }
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<bool>> updateField(
      String refResidence, String field, dynamic value) {
    return updateResidence(refResidence, {field: value});
  }

  @override
  Future<Result<List<Map<String, String>>>> getAllLocalisation(
      String residenceId) async {
    try {
      final structureRef = _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("structures");

      final querySnapshot = await structureRef.get();

      var allLocalisation = <Map<String, String>>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final structure = StructureResidence.fromJson(data, doc.id);

        if (structure.name.isNotEmpty && structure.type.isNotEmpty) {
          allLocalisation.add({
            'id': doc.id,
            'label': "${structure.type} ${structure.name}",
          });
        }
      }

      // Supprimer les doublons
      allLocalisation =
          {for (var loc in allLocalisation) loc['label']!: loc}
              .values
              .toList();

      // Trier par longueur puis alphabétiquement
      allLocalisation.sort((a, b) {
        if (a['label']!.length != b['label']!.length) {
          return a['label']!.length.compareTo(b['label']!.length);
        }
        return a['label']!.compareTo(b['label']!);
      });

      return Result.success(allLocalisation);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<StructureResidence?>> getDetailLocalisation(
      String residenceId, String locId) async {
    try {
      final doc = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("structures")
          .doc(locId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Result.success(StructureResidence.fromJson(data, doc.id));
      } else {
        return const Result.success(null);
      }
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<StructureResidence>>> getStructuresByResidence(
      String residenceId) async {
    try {
      final querySnapshot = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("structures")
          .get();

      final structures = querySnapshot.docs
          .map((docSnapshot) =>
              StructureResidence.fromJson(docSnapshot.data(), docSnapshot.id))
          .toList();

      structures.sort((a, b) {
        final lengthComparison = a.name.length.compareTo(b.name.length);
        if (lengthComparison != 0) {
          return lengthComparison;
        }
        return a.name.compareTo(b.name);
      });

      return Result.success(structures);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removeCsMember(
      String residenceId, String uidToRemove) async {
    try {
      await _firestore.collection('residences').doc(residenceId).update({
        'csmembers': FieldValue.arrayRemove([uidToRemove])
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> addCsMember(String residenceId, String uidToAdd) async {
    try {
      await _firestore.collection('residences').doc(residenceId).update({
        'csmembers': FieldValue.arrayUnion([uidToAdd])
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> saveStructure(
      String residenceId, StructureResidence structure) async {
    try {
      final collectionRef = _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("structures");

      if (structure.id == null || structure.id!.isEmpty) {
        final docRef = await collectionRef.add(structure.toJson());
        structure.id = docRef.id;
      } else {
        await collectionRef.doc(structure.id).update(structure.toJson());
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removeStructure(
      String residenceId, String structureId) async {
    try {
      await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("structures")
          .doc(structureId)
          .delete();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
