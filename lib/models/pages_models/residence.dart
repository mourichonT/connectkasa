import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/models/pages_models/address.dart';
import 'package:konodal/models/pages_models/agency.dart';
import 'package:konodal/models/pages_models/gerance_ref.dart';
import 'package:konodal/models/pages_models/structure_residence.dart';

class Residence {
  String name;
  // Regroupés sous 'address' côté Firestore (évite la duplication avec
  // Agency, qui a les mêmes champs) ; getters/setters ci-dessous pour
  // ne pas casser tous les appelants existants qui lisent/écrivent
  // .street/.zipCode/.city directement.
  Address address;
  String? mailContact;
  String id;
  // Maintenu automatiquement par la Cloud Function sync_lot_count
  // (functions_python/main.py), jamais écrit depuis le client.
  int totalLot;
  List<String>? csmembers;
  // syndicAgency : cache d'affichage (résolu depuis geranceRef, ou saisie
  // custom si non référencée dans gerances). geranceRef et syndicAgency ne
  // sont jamais tous les deux non-null en base : voir saveResidence() dans
  // management_res_info_g.dart.
  Agency? syndicAgency;
  GeranceRef? geranceRef;

  /// Plusieurs bâtiments identifiés par leur nom (ex: 'batA')
  Map<String, StructureResidence>? structures;

  String get street => address.street;
  set street(String value) => address.street = value;
  String get zipCode => address.zipCode;
  set zipCode(String value) => address.zipCode = value;
  String get city => address.city;
  set city(String value) => address.city = value;
  String get codeQualite => address.codeQualite;
  set codeQualite(String value) => address.codeQualite = value;

  Residence({
    required this.name,
    required String street,
    required String zipCode,
    required String city,
    String codeQualite = '60',
    required this.id,
    this.mailContact,
    this.csmembers,
    this.totalLot = 0,
    this.syndicAgency,
    this.geranceRef,
    this.structures,
  }) : address = Address(
          street: street,
          zipCode: zipCode,
          city: city,
          codeQualite: codeQualite,
        );

  /// Création à partir d'un JSON
  factory Residence.fromJson(Map<String, dynamic> json) {
    final structuresData = json['structures'] as Map<String, dynamic>?;
    final address = Address.fromJson(json['address']);

    return Residence(
      name: json['name'] ?? '',
      street: address.street,
      zipCode: address.zipCode,
      city: address.city,
      codeQualite: address.codeQualite,
      id: json['id'] ?? '',
      mailContact: json['mail_contact'],
      csmembers: (json['csmembers'] as List?)?.cast<String>(),
      totalLot: json['totalLot'] ?? 0,
      syndicAgency: json['syndicAgency'] != null
          ? Agency.fromJson(json['syndicAgency'])
          : null,
      geranceRef: json['geranceRef'] != null
          ? GeranceRef.fromJson(json['geranceRef'])
          : null,
      structures: structuresData?.map(
        (key, value) => MapEntry(key, StructureResidence.fromJson(value, key)),
      ),
    );
  }

  /// Création à partir d'un document Firestore
  factory Residence.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    final address = Address.fromJson(data?['address']);

    return Residence(
      name: data?['name'] ?? '',
      street: address.street,
      zipCode: address.zipCode,
      city: address.city,
      codeQualite: address.codeQualite,
      id: snapshot.id,
      mailContact: data?['mail_contact'],
      csmembers: (data?['csmembers'] as List?)?.cast<String>(),
      totalLot: data?['totalLot'] ?? 0,
      syndicAgency: data?['syndicAgency'] != null
          ? Agency.fromJson(data!['syndicAgency'])
          : null,
      geranceRef: data?['geranceRef'] != null
          ? GeranceRef.fromJson(data!['geranceRef'])
          : null,
    );
  }

  /// Charge la sous-collection "structure" et la place dans la map `structures`
  Future<void> loadStructures() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("residences")
        .doc(id)
        .collection("structures")
        .get();

    final Map<String, StructureResidence> loadedStructures = {};

    for (var doc in querySnapshot.docs) {
      loadedStructures[doc.id] =
          StructureResidence.fromJson(doc.data(), doc.id);
    }

    // Trie par longueur du nom puis alphabétique
    final sortedEntries = loadedStructures.entries.toList()
      ..sort((a, b) {
        int cmp = a.value.name.length.compareTo(b.value.name.length);
        if (cmp != 0) return cmp;
        return a.value.name.compareTo(b.value.name);
      });

    structures = Map.fromEntries(sortedEntries);
  }

  /// Sérialisation en JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address.toJson(),
      'mail_contact': mailContact,
      'id': id,
      'csmembers': csmembers,
      'totalLot': totalLot,
      'syndicAgency': syndicAgency?.toJson(),
      'geranceRef': geranceRef?.toJson(),
      'structures': structures?.map(
        (key, structure) => MapEntry(key, structure.toJson()),
      ),
    };
  }

  /// Crée une instance Residence et charge ses structures en même temps
  static Future<Residence> fromFirestoreWithStructures(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) async {
    final residence = Residence.fromFirestore(snapshot, options);
    await residence.loadStructures();
    return residence;
  }
}
