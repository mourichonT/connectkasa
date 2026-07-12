import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:konodal/core/utils/app_logger.dart';

class FetchPdfreport {
  Future<void> fetchPdf(String docRes) async {
    final response = await http.post(
      Uri.parse(
          "https://us-central1-konodal-dev.cloudfunctions.net/generate_report"),
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
