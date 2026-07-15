import 'dart:convert';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:http/http.dart' as http;
import 'package:konodal/core/utils/app_logger.dart';

const String _fallbackSupportEmail = 'admin.konodal@gmail.com';

/// Email envoyé au contact de la résidence suite à une demande de
/// modification des informations d'un ou plusieurs lots (bouton "Demander
/// une modification" de ModifyPropDetails) - modèle adapté de
/// sendDemandeEmail/send_demande_email. N'écrit aucune donnée Firestore :
/// notification pure, à charge d'un CS member d'appliquer le changement.
Future<void> sendModificationRequestEmail({
  required String requesterUid,
  required String? residenceMailContact,
  required String residenceName,
  required String lotsSummary,
  required List<Map<String, String>> changes,
}) async {
  final requester = await FirestoreUserRepository()
      .getUserById(requesterUid)
      .then((result) => result.when(success: (v) => v, failure: (_) => null));
  if (requester == null) return;

  final toEmail =
      (residenceMailContact != null && residenceMailContact.trim().isNotEmpty)
          ? residenceMailContact
          : _fallbackSupportEmail;

  final url = Uri.parse(
      'https://us-central1-konodal-dev.cloudfunctions.net/send_modification_request_email');

  final body = jsonEncode({
    'email': toEmail,
    'requesterName': requester.name,
    'requesterSurname': requester.surname,
    'requesterEmail': requester.email,
    'residenceName': residenceName,
    'lotsSummary': lotsSummary,
    'changes': changes,
  });

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    appLog('Email de demande de modification envoyé avec succès');
  } else {
    appLog(
        'Erreur lors de l\'envoi de l\'email de demande de modification: ${response.statusCode}');
    appLog('Réponse: ${response.body}');
    throw Exception('Envoi échoué (${response.statusCode})');
  }
}
