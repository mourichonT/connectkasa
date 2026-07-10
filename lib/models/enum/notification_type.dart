class NotificationType {
  // Clé Firestore (notificationPrefs.<clé> et data.type des push FCM) +
  // libellé affiché. Les 5 premières clés correspondent aux types de
  // publication de TypeList.typeDeclaration() (le payload FCM de
  // notifyNewPost transporte postData.type), les 2 dernières aux triggers
  // Cloud Functions notifyNewMessage / notifyDemandeLoc.
  static const List<List<String>> all = [
    ["sinistres", "Sinistres"],
    ["incivilites", "Incivilités"],
    ["communication", "Communications"],
    ["annonces", "Petites annonces"],
    ["events", "Événements"],
    ["message", "Messages"],
    ["demande_loc", "Demandes de location"],
  ];

  static Map<String, bool> get defaultPrefs =>
      {for (final type in all) type[0]: true};
}
