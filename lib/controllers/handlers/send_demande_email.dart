import 'dart:convert';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:http/http.dart' as http;
import 'package:konodal/core/utils/app_logger.dart';

/// Email envoyé au bailleur destinataire d'une demande de location (modèle
/// adapté de sendCustomEmail/send_custom_email, utilisé pour les sinistres).
Future<void> sendDemandeEmail({
  required String tenantUid,
  required String landlordEmail,
  String? lotAddress,
  String? lotNumero,
}) async {
  final tenant = await FirestoreUserRepository()
      .getUserById(tenantUid)
      .then((result) => result.when(success: (v) => v, failure: (_) => null));
  if (tenant == null) return;

  final url = Uri.parse(
      'https://us-central1-konodal-dev.cloudfunctions.net/send_demande_email');

  final body = jsonEncode({
    'email': landlordEmail,
    'tenantName': tenant.name,
    'tenantSurname': tenant.surname,
    'tenantEmail': tenant.email,
    'lotAddress': lotAddress ?? '',
    'lotNumero': lotNumero ?? '',
  });

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    appLog('Email de demande envoyé avec succès');
  } else {
    appLog('Erreur lors de l\'envoi de l\'email de demande: ${response.statusCode}');
    appLog('Réponse: ${response.body}');
  }
}
