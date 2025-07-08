import 'package:connect_kasa/models/pages_models/agency.dart';

class StructureResidence {
  String? id; // Cet ID sera l'ID du document Firestore

  String name;
  String type;
  List<String>? elements;
  List<String>? etage;
  List<String>? undergroundLevel;
  bool hasUnderground;
  bool hasDifferentSyndic;
  Agency? syndicAgency;
  String? refGerance;
  bool isExpanded;

  StructureResidence({
    this.id, // L'ID est optionnel lors de la création d'un nouvel objet
    required this.name,
    required this.type,
    this.elements,
    this.etage,
    this.undergroundLevel,
    this.hasUnderground = false,
    this.hasDifferentSyndic = false,
    this.syndicAgency,
    this.refGerance,
    this.isExpanded = true,
  });

  Map<String, dynamic> toJson() {
    // L'ID du document n'est PAS inclus ici, car il sera l'ID du document Firestore lui-même.
    // Les données JSON représentent ce qui est À L'INTÉRIEUR du document.
    return {
      'name': name,
      'type': type,
      'elements': elements,
      'etage': etage,
      'undergroundLevel': undergroundLevel,
      'hasUnderground': hasUnderground,
      'hasDifferentSyndic': hasDifferentSyndic,
      'syndicAgency': syndicAgency?.toJson(),
      'refGerance': refGerance,
      'isExpanded': isExpanded,
    };
  }

  factory StructureResidence.fromJson(Map<String, dynamic> json, String docId) {
    // Le docId est passé explicitement ici pour être assigné à l'objet
    return StructureResidence(
      id: docId, // Assignez l'ID du document Firestore ici
      name: json['name'],
      type: json['type'],
      elements: (json['elements'] as List?)?.map((e) => e.toString()).toList(),
      etage: (json['etage'] as List?)?.map((e) => e.toString()).toList(),
      undergroundLevel: (json['undergroundLevel'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      hasUnderground: json['hasUnderground'] ?? false,
      hasDifferentSyndic: json['hasDifferentSyndic'] ?? false,
      syndicAgency: json['syndicAgency'] != null
          ? Agency.fromJson(json['syndicAgency'])
          : null,
      refGerance: json['refGerance'],
      // isExpanded: json['isExpanded'] ?? true,
    );
  }
}
