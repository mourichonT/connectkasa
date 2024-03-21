class Lot {
  String _name = "";
  String refLot;
  String? batiment;
  String? lot;
  //Color colorSelected; // Modifier le type de colorSelected
  String type;
  String idProprietaire;
  List<String>? idLocataire;
  String residenceId;
  Map<String, dynamic> residenceData;

  Lot({
    String name = "",
    required this.refLot,
    this.batiment,
    this.lot,
    // required this.colorSelected,
    required this.type,
    required this.idProprietaire,
    this.idLocataire,
    required this.residenceId,
    required this.residenceData,
  }) : _name = name;

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      name: json["name"] ?? "",
      refLot: json["refLot"] ?? "",
      batiment: json["batiment"] ?? "",
      lot: json["lot"] ?? "",
      type: json["type"] ?? "",
      idProprietaire: json["idProprietaire"] ?? "",
      idLocataire: json["idLocataire"] != null
          ? List<String>.from(json["idLocataire"])
          : null,
      residenceId: json["residenceId"] ?? "",
      residenceData: json["residenceData"] != null
          ? Map<String, dynamic>.from(json["residenceData"])
          : {}, // Par défaut, initialiser residenceData avec un objet vide
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "refLot": refLot,
      "batiment": batiment,
      "lot": lot,
      //"colorSelected": colorSelected.value, // Utiliser value pour obtenir la valeur de la couleur
      "type": type,
      "idProprietaire": idProprietaire,
      "idLocataire": idLocataire,
      "residenceId": residenceId,
      "residenceData":
          residenceData, // Ajouter residenceData lors de la conversion en JSON
    };
  }

  void setNumLoc(String newValue) {
    _addNumLoc(newValue);
  }

  void _addNumLoc(String newValue) {
    idLocataire?.add(newValue);
  }

  String get name {
    return _name;
  }

  set newName(String newName) {
    if (name != newName) {
      _name = newName;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (_name.isNotEmpty) "name": name,
      if (refLot.isNotEmpty) "refLot": refLot,
      if (batiment != null) "batiment": batiment,
      if (lot != null) "lot": lot,
      //if (colorSelected != null) "colorSelected": colorSelected.value,
      if (type.isNotEmpty) "type": type,
      if (idProprietaire.isNotEmpty) "idProprietaire": idProprietaire,
      if (idLocataire != null) "idLocataire": idLocataire,
      "residenceId": residenceId,

      "residenceData":
          residenceData, // Ajouter residenceData lors de l'envoi à Firestore
    };
  }

  factory Lot.fromMap(Map<String, dynamic> map) {
    return Lot(
      name: map['name'] ?? "",
      refLot: map['refLot'] ?? "",
      batiment: map['batiment'],
      lot: map['lot'],
      //colorSelected: Color(map['colorSelected']), // Utiliser Color au lieu de MaterialColor
      type: map['type'] ?? "",
      idProprietaire: map['idProprietaire'] ?? "",
      idLocataire: List<String>.from(map['idLocataire'] ?? []),
      residenceId: map["residenceId"] ?? "",
      residenceData: {}, // Par défaut, initialiser residenceData avec un objet vide
    );
  }
}
