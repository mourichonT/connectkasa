import 'dart:convert';
import 'dart:io';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:konodal/core/utils/app_logger.dart';

class Exportpdfhttp {
  static Future<void> exportLocaScore(
      BuildContext context, UserInfo tenant) async {
    Uri url = Uri.parse("https://export-locascore-pdf-z5w73fjiva-uc.a.run.app");
    try {
      // Convertir l'objet UserInfo en JSON
      final Map<String, dynamic> tenantMap = tenant.toMapForExport();
      appLog(tenantMap);

      // Envoyer la requête HTTP POST
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(tenantMap),
      );

      if (response.statusCode == 200) {
        final pdfBytes = response.bodyBytes;

        // Obtenir le répertoire temporaire
        final directory = await getTemporaryDirectory();
        final fileName = "fiche_locataire_${tenant.name}_${tenant.surname}.pdf";
        final filePath = '${directory.path}/$fileName';

        // Écrire les bytes dans un fichier local
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        appLog("Fichier PDF enregistré à : $filePath");

        if (await file.exists()) {
          appLog("Le fichier existe à l'emplacement : ${file.path}");
          appLog("Taille du fichier : ${pdfBytes.length} octets");

          final result = await OpenFilex.open(file.path);
          if (result.type == ResultType.done) {
            appLog("Fichier ouvert avec succès.");
          } else {
            appLog("Erreur lors de l'ouverture du fichier : ${result.message}");
          }
        } else {
          appLog("Le fichier n'existe pas, impossible de l'ouvrir.");
        }
      } else {
        appLog(
            "Erreur lors de la génération du fichier PDF : ${response.statusCode}");
      }
    } catch (e) {
      appLog("Erreur lors de l'envoi de la requête : $e");
    }
  }

  static Future<void> fetchPostPdf(
    BuildContext context, {
    required String residenceId,
    required String postId,
  }) async {
    final Uri url = Uri.parse(
      "https://us-central1-konodal-dev.cloudfunctions.net/generate_report",
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "residenceId": residenceId,
          "postId": postId,
        }),
      );

      if (response.statusCode == 200) {
        final pdfBytes = response.bodyBytes;

        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/rapport_signalements_$postId.pdf';

        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        final result = await OpenFilex.open(file.path);
        if (result.type == ResultType.done) {
          appLog("PDF ouvert avec succès.");
        } else {
          appLog("Erreur à l'ouverture : ${result.message}");
        }
      } else {
        appLog("Erreur HTTP : ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      appLog("Erreur lors de l'appel à la Cloud Function : $e");
    }
  }
}
