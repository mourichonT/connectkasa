enum StatutPostList {
  nonEnvoye('Non envoyé'),
  transmis('Transmis'),
  enCours('En cours'),
  termine('Terminé'),
  empty('');

  final String label;

  const StatutPostList(this.label);

  // Méthode de conversion de chaîne de caractères en élément de l'énumération
  static StatutPostList fromString(String statusString) {
    switch (statusString) {
      case 'Non envoyé':
        return StatutPostList.nonEnvoye;
      case 'Transmis':
        return StatutPostList.transmis;
      case 'En cours':
        return StatutPostList.enCours;
      case 'Terminé':
        return StatutPostList.termine;
      default:
        return StatutPostList.empty; // Retourne null si aucune correspondance
    }
  }
}
