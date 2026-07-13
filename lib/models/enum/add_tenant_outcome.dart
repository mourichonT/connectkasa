/// Résultat de ILotRepository.addTenant() : la couche données ne fait plus
/// d'UI (SnackBar/dialog) elle-même, elle se contente de renvoyer un
/// verdict à charge pour l'appelant de décider quoi afficher.
enum AddTenantOutcome {
  /// Le locataire a bien été ajouté (ou remplacé) sur le lot.
  added,

  /// Ce locataire est déjà présent sur le lot, rien à faire.
  alreadyPresent,

  /// Le lot a déjà au moins un locataire différent : l'appelant doit
  /// demander à l'utilisateur "remplacer" ou "ajouter un colocataire" puis
  /// rappeler addTenant() avec le paramètre replace renseigné.
  needsReplaceOrAddDecision,
}
