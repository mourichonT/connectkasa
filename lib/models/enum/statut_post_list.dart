enum StatutPostList {
  enAttente('En attente'), // En attente
  priseEnCompte("Prise en compte"), // Prise en compte
  termine("Terminé"),
  empty('');

  final String label;

  const StatutPostList(this.label);

  // Méthode de conversion de chaîne de caractères en élément de l'énumération
  static StatutPostList fromString(String statusString) {
    switch (statusString) {
      case 'En attente':
        return StatutPostList.enAttente;
      case 'Prise en compte':
        return StatutPostList.priseEnCompte;
      case 'Terminé':
        return StatutPostList.termine;
      default:
        return StatutPostList.empty; // Retourne null si aucune correspondance
    }
  }
}
