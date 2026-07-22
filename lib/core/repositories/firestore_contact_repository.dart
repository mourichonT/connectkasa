import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/services/firestore_paths.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/contact_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/contact.dart';

class FirestoreContactRepository implements IContactRepository {
  final FirebaseFirestore _firestore;

  FirestoreContactRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection RACINE (pas residences/{id}/contacts) - cf. commentaire
  // firestore.rules sur la collision de nom avec gerances/{id}/contacts.
  CollectionReference<Map<String, dynamic>> get _contacts =>
      _firestore.collection(FirestorePaths.contacts);

  @override
  Future<Result<List<Contact>>> getEmergenciesContacts() async {
    try {
      final querySnapshot =
          await _firestore.collection("emergencyContactsFr").get();
      final contacts = querySnapshot.docs
          .map((docSnapshot) => Contact.fromJson(docSnapshot.data()))
          .toList();
      return Result.success(contacts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Contact>>> getContactsByResidence(
      String residenceId) async {
    try {
      final residenceSnapshot =
          await _firestore.collection("residences").doc(residenceId).get();
      final contactRefs =
          (residenceSnapshot.data()?['contactRefs'] as Map<String, dynamic>?) ??
              {};
      final contactIds = contactRefs.keys.toList();
      if (contactIds.isEmpty) {
        return const Result.success([]);
      }

      // whereIn (documentId) est limité à 30 éléments par requête - on
      // découpe par lots pour les résidences avec beaucoup de contacts liés.
      final contacts = <Contact>[];
      for (var i = 0; i < contactIds.length; i += 30) {
        final batchIds = contactIds.sublist(
            i, i + 30 > contactIds.length ? contactIds.length : i + 30);
        final querySnapshot = await _contacts
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        contacts.addAll(querySnapshot.docs
            .map((docSnapshot) => Contact.fromJson(docSnapshot.data())));
      }
      return Result.success(contacts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Contact>>> findContactsByNameNormalized(
      String nameNormalized) async {
    try {
      final querySnapshot = await _contacts
          .where('nameNormalized', isEqualTo: nameNormalized)
          .get();
      final contacts = querySnapshot.docs
          .map((docSnapshot) => Contact.fromJson(docSnapshot.data()))
          .toList();
      return Result.success(contacts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Contact>> createContact(
      String residenceId, Contact contact) async {
    try {
      // Verrouillé : une création côté app ne peut jamais s'auto-approuver
      // (cf. firestore.rules) - seul un Super Admin peut faire passer
      // isApproved à true après revue.
      contact.isApproved = false;

      final docRef = await _contacts.add(contact.toJson());
      contact.id = docRef.id;
      await docRef.update({'id': contact.id});
      await _firestore.collection("residences").doc(residenceId).update({
        'contactRefs.${docRef.id}': true,
      });

      return Result.success(contact);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> updateContact(Contact contact) async {
    try {
      if (contact.id == null || contact.id!.isEmpty) {
        return Result.failure(
            const UnknownException("L'identifiant du contact est manquant."));
      }

      await _contacts.doc(contact.id).update(contact.toJson());
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> linkResidence(
      String contactId, String residenceId) async {
    try {
      await _firestore.collection("residences").doc(residenceId).update({
        'contactRefs.$contactId': true,
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> unlinkResidence(
      String contactId, String residenceId) async {
    try {
      // Efface la clé, jamais un delete du contact : il reste dans
      // l'annuaire partagé même si plus aucune résidence ne le référence
      // (cf. IContactRepository).
      await _firestore.collection("residences").doc(residenceId).update({
        'contactRefs.$contactId': FieldValue.delete(),
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
