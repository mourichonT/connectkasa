import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> generateUniqueRefUserApp(FirebaseFirestore firestore, String uid) async {
  String refUserApp = uid.substring(0, 8); // Prend les 8 premiers caractères de l'UID
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
      refUserApp = uid.substring(0, 7) + String.fromCharCode(uid.codeUnitAt(7) + attempt % 26);
      attempt++;
    }
  }

  return refUserApp;
}
