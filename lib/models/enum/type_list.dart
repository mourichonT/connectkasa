class TypeList {
  List<List<String>> typeDeclaration() {
    return [
      ["Sinistre", "sinistres"],
      ["Incivilité", "incivilites"],
      ["Communication", "communication"],
      ["Petite annonce", "annonces"],
      ["Evénement", "events"],
    ];
  }

  List<String> categoryAnnonce() {
    return [
      "Appartement",
      "Electroménager",
      "Jeux et jouet",
      "Meubles",
      "Mode",
      "Outils",
      "Parking",
      "Services",
      "Sport et plein air",
      "Véhicule"
    ];
  }

  List<String> categoryDocs() {
    return [
      "Gestion du syndic",
      "Assemblées générales",
      "Contrats et marchés",
      "Assurances",
      "Carnet d'entretien et gestion technique",
      "Synthèse et fiches officielles",
      "Documents juridiques de la copropriété"
    ];
  }

  static List<String> idTypes = [
    "Carte d'identité",
    "Permis de conduire",
    "Passeport",
    "Titre de séjour",
  ];

  static List<String> justifTypeProps = [
    "Attestation de propriété ",
  ];
  static List<String> justifTypeLocs = [
    "Facture d'eau",
    "Facture téléphone",
    "Facture d'electricité",
    "Contrat de bail",
  ];
}
