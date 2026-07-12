/// Met une majuscule sur le premier caractère non-blanc d'un texte libre,
/// sans toucher au reste (pas de lowercase forcé sur le reste de la chaîne,
/// pour ne pas écraser des sigles/noms propres déjà bien casés).
String capitalizeFirstLetter(String text) {
  final index = text.indexOf(RegExp(r'\S'));
  if (index == -1) return text;
  return text.replaceRange(index, index + 1, text[index].toUpperCase());
}
