import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:connect_kasa/core/utils/app_logger.dart';

class FetchPdfreport {
  Future<void> fetchPdf(String docRes) async {
    final response = await http.post(
      Uri.parse(
          "https://europe-west1-connectkasa-84f23.cloudfunctions.net/generate_report"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"docRes": docRes}),
    );

    if (response.statusCode == 200) {
      // Sauvegarder le PDF localement ou l'ouvrir
      appLog("PDF téléchargé !");
    } else {
      appLog("Erreur: ${response.body}");
    }
  }
}
