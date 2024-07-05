import 'package:flutter/foundation.dart';

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
}
