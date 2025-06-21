import 'package:connect_kasa/models/pages_models/agency.dart';

class StructureResidence {
  String name;
  String type;
  List<String>? elements;
  List<String>? etage;
  List<String>? undergroundLevel;
  bool hasUnderground;
  bool hasDifferentSyndic;
  Agency? syndicAgency;
  String? refGerance;
  bool isExpanded; // NOUVELLE PROPRIÉTÉ: pour gérer l'état replié/déplié

  StructureResidence({
    required this.name,
    required this.type,
    this.elements,
    this.etage,
    this.undergroundLevel,
    this.hasUnderground = false,
    this.hasDifferentSyndic = false,
    this.syndicAgency,
    this.refGerance,
    this.isExpanded = true, // Initialise à true (déplié) par défaut
  });

  Map<String, dynamic> toJson() {
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
      'isExpanded': isExpanded, // Inclure dans la conversion JSON
    };
  }

  factory StructureResidence.fromJson(Map<String, dynamic> json) {
    return StructureResidence(
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
      isExpanded:
          json['isExpanded'] ?? true, // Récupère la valeur ou true par défaut
    );
  }
}
