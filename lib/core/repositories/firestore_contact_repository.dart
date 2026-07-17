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
      final querySnapshot = await _contacts
          .where('residencesIds', arrayContains: residenceId)
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
      contact.residencesIds = [residenceId];
      // Verrouillé : une création côté app ne peut jamais s'auto-approuver
      // (cf. firestore.rules) - seul un Super Admin peut faire passer
      // isApproved à true après revue.
      contact.isApproved = false;

      final docRef = await _contacts.add(contact.toJson());
      contact.id = docRef.id;
      await docRef.update({'id': contact.id});

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
      await _contacts.doc(contactId).update({
        'residencesIds': FieldValue.arrayUnion([residenceId]),
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
      // arrayRemove, jamais un delete : le contact reste dans l'annuaire
      // partagé même si residencesIds devient vide (cf. IContactRepository).
      await _contacts.doc(contactId).update({
        'residencesIds': FieldValue.arrayRemove([residenceId]),
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
