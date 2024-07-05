class Lot {
  String _nameProp = "";
  String _nameLoc = "";
  String refLot;
  String? batiment;
  String? lot;
  String typeLot;
  //Color colorSelected; // Modifier le type de colorSelected
  String? refGerance;
  String type;
  List<String>? idProprietaire;
  List<String>? idLocataire;
  String residenceId;
  Map<String, dynamic> residenceData;

  Lot({
    String nameProp = "",
    String nameLoc = "",
    required this.refLot,
    this.batiment,
    this.lot,
    required this.typeLot,
    // required this.colorSelected,
    this.refGerance,
    required this.type,
    required this.idProprietaire,
    this.idLocataire,
    required this.residenceId,
    required this.residenceData,
  })  : _nameProp = nameProp,
        _nameLoc = nameLoc;

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      nameProp: json["nameProp"] ?? "",
      nameLoc: json["nameLoc"] ?? "",
      refLot: json["refLot"] ?? "",
      batiment: json["batiment"] ?? "",
      lot: json["lot"] ?? "",
      typeLot: json["typeLot"] ?? "",
      type: json["type"] ?? "",
      refGerance: json["refGerance"] ?? "",
      idProprietaire:
          json["idProprietaire"] != null && json["idProprietaire"] is List
              ? List<String>.from(json["idProprietaire"])
              : null,
      idLocataire: json["idLocataire"] != null && json["idLocataire"] is List
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
      "nameProp": nameProp,
      "nameLoc": nameLoc,
      "refLot": refLot,
      "refGerance": refGerance,
      "batiment": batiment,
      "lot": lot,
      "typeLot": typeLot,
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

  void setNumProp(String newValue) {
    _addNumProp(newValue);
  }

  void _addNumProp(String newValue) {
    idProprietaire?.add(newValue);
  }

  String get nameProp {
    return _nameProp;
  }

  String get nameLoc {
    return _nameLoc;
  }

  set newNameProp(String newName) {
    if (nameProp != newName) {
      _nameProp = newName;
    }
  }

  set newNameLoc(String newName) {
    if (nameLoc != newName) {
      _nameLoc = newName;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (_nameProp.isNotEmpty) "nameProp": nameProp,
      if (_nameLoc.isNotEmpty) "nameLoc": nameLoc,
      if (refLot.isNotEmpty) "refLot": refLot,
      "refGerance": refGerance,
      if (batiment != null) "batiment": batiment,
      if (lot != null) "lot": lot,
      "typeLot": typeLot,
      //if (colorSelected != null) "colorSelected": colorSelected.value,
      if (type.isNotEmpty) "type": type,
      if (idProprietaire != null) "idProprietaire": idProprietaire,
      if (idLocataire != null) "idLocataire": idLocataire,
      "residenceId": residenceId,

      "residenceData":
          residenceData, // Ajouter residenceData lors de l'envoi à Firestore
    };
  }

  factory Lot.fromMap(Map<String, dynamic> map) {
    return Lot(
      nameProp: map['nameProp'] ?? "",
      nameLoc: map['nameLoc'] ?? "",
      refLot: map['refLot'] ?? "",
      batiment: map['batiment'],
      lot: map['lot'],
      typeLot: map['typeLot'],
      refGerance: map["refGerance"],
      //colorSelected: Color(map['colorSelected']), // Utiliser Color au lieu de MaterialColor
      type: map['type'] ?? "",
      idProprietaire: List<String>.from(map['idProprietaire'] ?? []),
      idLocataire: List<String>.from(map['idLocataire'] ?? []),
      residenceId: map["residenceId"] ?? "",
      residenceData: {}, // Par défaut, initialiser residenceData avec un objet vide
    );
  }
}
