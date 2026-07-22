import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/contact.dart';

/// Contacts ("annuaire prestataires") : collection racine "contacts",
/// partagée entre résidences. Le rattachement à une résidence vit sur
/// residences/{id}.contactRefs (map {contactId: true}), PAS sur le document
/// contact lui-même - Firestore n'a pas de sécurité par champ, donc un
/// tableau de résidences exposé sur un document partagé lisible par
/// plusieurs agences aurait fait fuiter les résidences des autres agences à
/// chacune d'elles. Remplace l'ancienne sous-collection
/// residences/{id}/contacts (un contact par résidence, pas de rapprochement
/// possible entre résidences).
abstract interface class IContactRepository {
  Future<Result<List<Contact>>> getEmergenciesContacts();

  Future<Result<List<Contact>>> getContactsByResidence(String residenceId);

  /// Candidats de rapprochement par nom normalisé (lowercase+trim), utilisé
  /// par manage_contact.dart AVANT de créer un nouveau contact, pour
  /// proposer de lier un contact existant plutôt que d'en dupliquer un.
  Future<Result<List<Contact>>> findContactsByNameNormalized(
      String nameNormalized);

  /// Crée un nouveau contact racine, rattaché uniquement à [residenceId]
  /// (résidences/{id}.contactRefs).
  Future<Result<Contact>> createContact(String residenceId, Contact contact);

  /// Met à jour un contact existant en place - si ce contact est partagé
  /// (rattaché à plusieurs résidences), l'édition se répercute sur toutes
  /// les résidences qui le référencent.
  Future<Result<void>> updateContact(Contact contact);

  /// Rattache [residenceId] à un contact déjà existant
  /// (residences/{id}.contactRefs.{contactId} = true), sans toucher aux
  /// autres champs - flux "Oui, même contact" de la modale de rapprochement.
  Future<Result<void>> linkResidence(String contactId, String residenceId);

  /// Détache [residenceId] d'un contact (efface
  /// residences/{id}.contactRefs.{contactId}). Ne supprime jamais le
  /// document contact, même si plus aucune résidence ne le référence : il
  /// reste dans l'annuaire partagé, réutilisable plus tard.
  Future<Result<void>> unlinkResidence(String contactId, String residenceId);
}
