import 'package:cloud_firestore/cloud_firestore.dart';

class Residence {
  String name;
  String numero;
  String voie;
  String street;
  String zipCode;
  String city;
  String refGerance;
  String id;
  List<String>? elements;
  List<String>? etage;
  List<String>? localisation;
  int nombreLot;
  List<String>? csmembers;

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
    this.elements,
    this.etage,
    this.localisation,
    this.nombreLot = 0,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
      name: json['name'] ?? '',
      numero: json['numero'] ?? '',
      voie: json['voie'] ?? '',
      street: json['street'] ?? '',
      zipCode: json['zipCode'] ?? '',
      city: json['city'] ?? '',
      refGerance: json['refGerance'] ?? '',
      id: json['id'] ?? '',
      csmembers:
          json['csmembers'] != null ? List<String>.from(json['csmembers']) : null,
      elements:
          json['elements'] != null ? List<String>.from(json['elements']) : null,
      etage: json['etage'] != null ? List<String>.from(json['etage']) : null,
      localisation: json['localistation'] != null
          ? List<String>.from(json['localistation'])
          : null,
      nombreLot: json['nombreLot'] ?? 0,
    );
  }

  factory Residence.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Residence(
      name: data?["name"] ?? '',
      numero: data?["numero"] ?? '',
      voie: data?["voie"] ?? '',
      street: data?["street"] ?? '',
      zipCode: data?["zipCode"] ?? '',
      city: data?["city"] ?? '',
      refGerance: data?["refGerance"] ?? '',
      id: data?["id"] ?? '',
      csmembers: data?["csmembers"] != null
          ? List<String>.from(data?["csmembers"])
          : null,
      elements: data?["elements"] != null
          ? List<String>.from(data?["elements"])
          : null,
      etage: data?["etage"] != null ? List<String>.from(data?["etage"]) : null,
      localisation: data?["localistation"] != null
          ? List<String>.from(data?["localistation"])
          : null,
      nombreLot: data?["nombreLot"] ?? 0,
    );
  }

  factory Residence.fromMap(Map<String, dynamic> map) {
    return Residence(
      name: map['name'] ?? '',
      numero: map['numero'] ?? '',
      voie: map['voie'] ?? '',
      street: map['street'] ?? '',
      zipCode: map['zipCode'] ?? '',
      city: map['city'] ?? '',
      refGerance: map['refGerance'] ?? '',
      id: map['id'] ?? '',
      csmembers:
          map['csmembers'] != null ? List<String>.from(map['csmembers']) : null,     
      elements:
          map['elements'] != null ? List<String>.from(map['elements']) : null,
      etage: map['etage'] != null ? List<String>.from(map['etage']) : null,
      localisation: map['localistation'] != null
          ? List<String>.from(map['localistation'])
          : null,
      nombreLot: map['nombreLot'] ?? 0,
    );
  }
}
