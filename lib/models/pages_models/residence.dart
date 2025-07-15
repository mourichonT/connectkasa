import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/structure_residence.dart';

class Residence {
  String name;
  String numero;
  String voie;
  String street;
  String zipCode;
  String city;
  String refGerance;
  String id;
  int nombreLot;
  List<String>? csmembers;
  Agency? syndicAgency;

  /// Plusieurs bâtiments identifiés par leur nom (ex: 'batA')
  Map<String, StructureResidence>? structures;

  Residence({
    required this.name,
    required this.numero,
    required this.voie,
    required this.street,
    required this.zipCode,
    required this.city,
    required this.refGerance,
    required this.id,
    this.csmembers,
    this.nombreLot = 0,
    this.syndicAgency,
    this.structures,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    final structuresData = json['structures'] as Map<String, dynamic>?;

    return Residence(
      name: json['name'] ?? '',
      numero: json['numero'] ?? '',
      voie: json['voie'] ?? '',
      street: json['street'] ?? '',
      zipCode: json['zipCode'] ?? '',
      city: json['city'] ?? '',
      refGerance: json['refGerance'] ?? '',
      id: json['id'] ?? '',
      csmembers: json['csmembers'] != null
          ? List<String>.from(json['csmembers'])
          : null,
      nombreLot: json['nombreLot'] ?? 0,
      syndicAgency: json['syndicAgency'] != null
          ? Agency.fromJson(json['syndicAgency'])
          : null,
    );
  }

  factory Residence.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    return Residence(
      name: data?['name'] ?? '',
      numero: data?['numero'] ?? '',
      voie: data?['voie'] ?? '',
      street: data?['street'] ?? '',
      zipCode: data?['zipCode'] ?? '',
      city: data?['city'] ?? '',
      refGerance: data?['refGerance'] ?? '',
      id: snapshot.id,
      csmembers: data?['csmembers'] != null
          ? List<String>.from(data!['csmembers'])
          : null,
      nombreLot: data?['nombreLot'] ?? 0,
      syndicAgency: data?['syndicAgency'] != null
          ? Agency.fromJson(data!['syndicAgency'])
          : null,
    );
  }

  /// Charge la sous-collection "structure" et la place dans la map `structures`
  Future<void> loadStructures() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("Residence")
        .doc(id)
        .collection("structure")
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'numero': numero,
      'voie': voie,
      'street': street,
      'zipCode': zipCode,
      'city': city,
      'refGerance': refGerance,
      'id': id,
      'csmembers': csmembers,
      'nombreLot': nombreLot,
      'syndicAgency': syndicAgency?.toJson(),
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
