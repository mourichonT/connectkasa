class StructureResidence {
  String name;
  String type;
  List<String>? elements;
  List<String>? etage;
  String? refGerance;

  StructureResidence({
    required this.name,
    required this.type,
    this.elements,
    this.etage,
    this.refGerance,
  });

  // Méthode pour convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'elements': elements,
      'etage': etage,
      'ref_gerance': refGerance,
    };
  }

  // Méthode pour créer une instance à partir d’un JSON
  factory StructureResidence.fromJson(Map<String, dynamic> json) {
    return StructureResidence(
      name: json['name'],
      type: json['type'],
      elements: (json['elements'] as List?)?.map((e) => e.toString()).toList(),
      etage: (json['etage'] as List?)?.map((e) => e.toString()).toList(),
      refGerance: json['ref_gerance'],
    );
  }
}
