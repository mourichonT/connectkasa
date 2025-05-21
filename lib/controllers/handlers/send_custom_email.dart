import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

Future<void> sendCustomEmail({
  required Lot lot,
  required Post post,
  required String email,
  required String subjectMail,
}) async {
  final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(
    post.timeStamp.toDate(),
  );
  final url = Uri.parse(
      'https://europe-west1-connectkasa-84f23.cloudfunctions.net/send_custom_email');

  final body = jsonEncode({
    'residenceId': post.refResidence,
    'postId': post.id,
    'email': email,
    'subjectMail': subjectMail,
    "residenceName": lot.residenceData['name'],
    "residenceNumero": lot.residenceData['numero'],
    "residenceVoie": lot.residenceData['voie'],
    "residenceStreet": lot.residenceData['street'],
    "residenceZipcode": lot.residenceData['zipCode'],
    "residenceCity": lot.residenceData['city'],
    "postTitle": post.title,
    "postImg": post.pathImage,
    "postLocalisation":
        " ${post.location_element} • Etage : ${post.location_floor} • Précision : ${post.location_details?.join(', ')}",
    "postDate": formattedDate,
    "postDescription": post.description,
  });

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    print('Email envoyé avec succès');
  } else {
    print('Erreur lors de l\'envoi de l\'email: ${response.statusCode}');
    print('Réponse: ${response.body}');
  }
}
