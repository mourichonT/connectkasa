enum StatutPostList {
  nonEnvoye('Non envoyé'),
  transmis('Transmis'),
  enCours('En cours'),
  termine('Terminé'),
  // Les deux suivants ne font PAS partie du workflow sinistre/incivilité
  // (statut, 4 valeurs ci-dessus) : ce sont les statuts d'une intervention
  // (type "events"), dérivés des booléens termine/reporte du post (cf.
  // header_row.dart) - jamais un statut de sinistre.
  programme('Programmé'),
  reporte('Reporté'),
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
      case 'Programmé':
        return StatutPostList.programme;
      case 'Reporté':
        return StatutPostList.reporte;
      default:
        return StatutPostList.empty; // Retourne null si aucune correspondance
    }
  }
}
