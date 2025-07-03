class Lot {
  String refLot;
  String? batiment;
  String? lot;
  String typeLot;
  String? refGerance;
  String type;
  List<String>? idProprietaire;
  List<String>? idLocataire;
  String residenceId;
  Map<String, dynamic> residenceData;
  Map<String, dynamic> userLotDetails;

  Lot({
    String nameProp = "",
    String nameLoc = "",
    required this.refLot,
    this.batiment,
    this.lot,
    required this.typeLot,
    this.refGerance,
    required this.type,
    required this.idProprietaire,
    this.idLocataire,
    required this.residenceId,
    required this.residenceData,
    required this.userLotDetails,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      refLot: json["refLot"] ?? "",
      batiment: json["batiment"],
      lot: json["lot"],
      typeLot: json["typeLot"] ?? "",
      refGerance: json["refGerance"],
      type: json["type"] ?? "",
      idProprietaire:
          json["idProprietaire"] != null && json["idProprietaire"] is List
              ? List<String>.from(json["idProprietaire"])
              : [],
      idLocataire: json["idLocataire"] != null && json["idLocataire"] is List
          ? List<String>.from(json["idLocataire"])
          : null,
      residenceId: json["residenceId"] ?? "",
      residenceData: json["residenceData"] != null
          ? Map<String, dynamic>.from(json["residenceData"])
          : {},
      userLotDetails: json["userLotDetails"] != null
          ? Map<String, dynamic>.from(json["userLotDetails"])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "refLot": refLot,
      "batiment": batiment,
      "lot": lot,
      "typeLot": typeLot,
      "refGerance": refGerance,
      "type": type,
      "idProprietaire": idProprietaire,
      "idLocataire": idLocataire,
      "residenceId": residenceId,
      "residenceData": residenceData,
      'userLotDetails': userLotDetails,
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

  Map<String, dynamic> toFirestore() {
    return {
      if (refLot.isNotEmpty) "refLot": refLot,
      "refGerance": refGerance,
      if (batiment != null) "batiment": batiment,
      if (lot != null) "lot": lot,
      "typeLot": typeLot,
      if (type.isNotEmpty) "type": type,
      if (idProprietaire != null) "idProprietaire": idProprietaire,
      if (idLocataire != null) "idLocataire": idLocataire,
      "residenceId": residenceId,
      "residenceData": residenceData,
      'userLotDetails': userLotDetails,
    };
  }

  factory Lot.fromMap(Map<String, dynamic> map) {
    return Lot(
      refLot: map['refLot'] ?? "",
      batiment: map['batiment'],
      lot: map['lot'],
      typeLot: map['typeLot'] ?? "",
      refGerance: map["refGerance"],
      type: map['type'] ?? "",
      idProprietaire: List<String>.from(map['idProprietaire'] ?? []),
      idLocataire: List<String>.from(map['idLocataire'] ?? []),
      residenceId: map["residenceId"] ?? "",
      residenceData: map["residenceData"] != null
          ? Map<String, dynamic>.from(map["residenceData"])
          : {},
      userLotDetails: map["userLotDetails"] != null
          ? Map<String, dynamic>.from(map["userLotDetails"])
          : {},
    );
  }
  Map<String, dynamic> toJsonForDb() {
    return {
      if (refLot.isNotEmpty) "refLot": refLot,
      if (refGerance != null) "refGerance": refGerance,
      if (batiment != null) "batiment": batiment,
      if (lot != null) "lot": lot,
      if (typeLot.isNotEmpty) "typeLot": typeLot,
      if (type.isNotEmpty) "type": type,
      if (idProprietaire != null) "idProprietaire": idProprietaire,
      //if (idLocataire != null) "idLocataire": idLocataire,
      //if (residenceId.isNotEmpty) "residenceId": residenceId,
      // NOTE : On ne met PAS userLotDetails ni residenceData
    };
  }
}
