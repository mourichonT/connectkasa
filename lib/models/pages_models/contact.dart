import 'package:konodal/models/pages_models/address.dart';

class Contact {
  String? id; // Doit être nullable pour les nouveaux contacts
  String name;
  String service;
  String phone;
  String? mail;
  // Regroupée sous 'address' côté Firestore, comme Residence/Agency (évite
  // numéro/rue/ville/code postal éparpillés) - cf. address.dart.
  Address address;
  String? web;
  // Ids d'autres contacts racine détectés comme doublons probables (même
  // nameNormalized, résidences source différentes) au moment de la
  // migration residences/*/contacts/* -> contacts/* - jamais fusionnés
  // automatiquement, à traiter manuellement côté backoffice.
  List<String> likelyDuplicateIds;
  // Un contact partagé ne doit jamais être modifiable par un CS member une
  // fois créé (l'édition impacterait silencieusement toutes les résidences
  // qui le référencent) : seule la création (isApproved: false par défaut)
  // reste possible côté app - le rattachement/détachement à une résidence se
  // fait désormais sur residences/{id}.contactRefs (pas sur ce document, cf.
  // IContactRepository.linkResidence/unlinkResidence), et toute correction
  // de champ passe par une validation manuelle d'un Super Admin (backoffice
  // web), qui repasse isApproved à true. Même logique verrouillée que
  // User.isApproved / lot isApprovedLot - cf. firestore.rules.
  bool isApproved;

  Contact({
    this.id, // <-- Ajouté ici
    required this.name,
    required this.phone,
    required this.service,
    Address? address,
    this.mail,
    this.web,
    List<String>? likelyDuplicateIds,
    this.isApproved = false,
  })  : address = address ?? Address(),
        likelyDuplicateIds = likelyDuplicateIds ?? [];

  factory Contact.fromJson(Map<String, dynamic> json) {
    // "address" absent : ancien format à plat (num/street/city/zipcode),
    // notamment emergencyContactsFr (allow write: if false - ne peut pas
    // être migré depuis l'app, seulement lu de façon rétrocompatible ici).
    final addressJson = json['address'] as Map<String, dynamic>?;
    final address = addressJson != null
        ? Address.fromJson(addressJson)
        : Address(
            street: [json['num'], json['street']]
                .whereType<String>()
                .where((s) => s.trim().isNotEmpty)
                .join(' '),
            zipCode: json['zipcode'] ?? '',
            city: json['city'] ?? '',
          );

    return Contact(
      id: json['id'], // <-- Ajouté ici
      name: json['name'],
      service: json['service'],
      phone: json['phone'],
      mail: json['mail'],
      address: address,
      web: json['web'],
      likelyDuplicateIds:
          (json['likelyDuplicateIds'] as List?)?.cast<String>() ?? [],
      // Absent sur emergencyContactsFr (jamais scopé résidence, pas soumis
      // à validation) : traité comme approuvé pour ne pas afficher un badge
      // "en attente" sur ces contacts-là.
      isApproved: json['isApproved'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // <-- Ajouté ici
      'name': name,
      'service': service,
      'phone': phone,
      'mail': mail,
      'address': address.toJson(),
      'web': web,
      // Dérivé de 'name' à chaque écriture (jamais un paramètre constructeur
      // séparé, pour ne jamais désynchroniser des deux) : clé de
      // rapprochement insensible à la casse utilisée par
      // findContactsByNameNormalized (manage_contact.dart) - "Servimmo" et
      // "servimmo" doivent matcher.
      'nameNormalized': name.trim().toLowerCase(),
      'likelyDuplicateIds': likelyDuplicateIds,
      'isApproved': isApproved,
    };
  }
}
