import 'dart:convert';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:konodal/core/utils/app_logger.dart';

Future<void> sendCustomEmail({
  required Lot lot,
  required Post post,
  required String email,
  required String subjectMail,
  String? declarantStatus,
}) async {
  final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(
    post.timeStamp.toDate(),
  );
  final url = Uri.parse(
      'https://us-central1-konodal-dev.cloudfunctions.net/send_custom_email');

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
        " ${post.locationElement} • Etage : ${post.locationFloor} • Précision : ${post.locationDetails?.join(', ')}",
    "postDate": formattedDate,
    "postDescription": post.description,
    "declarantStatus": declarantStatus ?? '',
  });

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    appLog('Email envoyé avec succès');
  } else {
    appLog('Erreur lors de l\'envoi de l\'email: ${response.statusCode}');
    appLog('Réponse: ${response.body}');
  }
}
