enum PostDeletionReason {
  contenuInapproprie('Contenu inapproprié'),
  spamOuPublicite('Spam ou publicité'),
  informationErroneeOuTrompeuse('Information erronée ou trompeuse'),
  doublon('Doublon'),
  erreurDePublication('Erreur de publication'),
  demandeDeLAuteur("Demande de l'auteur"),
  problemeResolu('Problème résolu'),
  autre('Autre');

  final String label;

  const PostDeletionReason(this.label);

  static List<String> labels() =>
      PostDeletionReason.values.map((e) => e.label).toList();
}
