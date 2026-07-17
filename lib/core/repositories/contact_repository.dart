import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/contact.dart';

/// Contacts ("annuaire prestataires") : collection racine "contacts",
/// partagée entre résidences via Contact.residencesIds - remplace l'ancienne
/// sous-collection residences/{id}/contacts (un contact par résidence, pas
/// de rapprochement possible entre résidences).
abstract interface class IContactRepository {
  Future<Result<List<Contact>>> getEmergenciesContacts();

  Future<Result<List<Contact>>> getContactsByResidence(String residenceId);

  /// Candidats de rapprochement par nom normalisé (lowercase+trim), utilisé
  /// par manage_contact.dart AVANT de créer un nouveau contact, pour
  /// proposer de lier un contact existant plutôt que d'en dupliquer un.
  Future<Result<List<Contact>>> findContactsByNameNormalized(
      String nameNormalized);

  /// Crée un nouveau contact racine, rattaché uniquement à [residenceId].
  Future<Result<Contact>> createContact(String residenceId, Contact contact);

  /// Met à jour un contact existant en place - si ce contact est partagé
  /// (residencesIds.length > 1), l'édition se répercute sur toutes les
  /// résidences qui le référencent.
  Future<Result<void>> updateContact(Contact contact);

  /// Rattache [residenceId] à un contact déjà existant (arrayUnion), sans
  /// toucher aux autres champs - flux "Oui, même contact" de la modale de
  /// rapprochement.
  Future<Result<void>> linkResidence(String contactId, String residenceId);

  /// Détache [residenceId] d'un contact (arrayRemove). Ne supprime jamais le
  /// document, même si residencesIds devient vide : le contact reste dans
  /// l'annuaire partagé, réutilisable plus tard.
  Future<Result<void>> unlinkResidence(String contactId, String residenceId);
}
