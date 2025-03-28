class ImmoList {
  static List<String> statutList() {
    return [
      "Location longue durée",
      "Location courte durée",
      "Propriétaire occupant",
      "Résidence secondaire",
    ];
  }

  static List<String> typeList() {
    return ["Propriétaire", "Locataire"];
  }

  static List<String> locaTypeList() {
    return [
      "Bail unique (personne seule)",
      "Bail co-titulaire (en concubinage)",
      "Bail en colocation"
    ];
  }

  static List<String> bienTypeList() {
    return [
      "Résidence Principale ou secondaire",
      "Investissement Locatif",
    ];
  }
}
