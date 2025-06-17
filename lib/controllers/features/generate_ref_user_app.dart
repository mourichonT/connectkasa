import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';

Future<String> generateUniqueRefUserApp(
    FirebaseFirestore firestore, UserTemp user) async {
  String refUserApp = user.uid
      .substring(0, 8)
      .toLowerCase(); // Prend les 8 premiers caractères de l'UID
  bool exists = true;
  int attempt = 0;

  while (exists) {
    var snapshot = await firestore
        .collection('User')
        .where('refUserApp', isEqualTo: refUserApp)
        .get();

    exists = snapshot.docs.isNotEmpty;

    if (exists) {
      // Modifier légèrement le dernier caractère (ex: changer 'A' en 'B')
      refUserApp = user.uid.substring(0, 7).toLowerCase() +
          String.fromCharCode(user.uid.codeUnitAt(7) + attempt % 26)
              .toLowerCase();
      attempt++;
    }
  }

  return refUserApp;
}
