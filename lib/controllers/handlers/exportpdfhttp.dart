import 'dart:convert';
import 'dart:io';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class Exportpdfhttp {
  static Future<void> ExportLocaScore(
      BuildContext context, UserInfo tenant) async {
    Uri url = Uri.parse("https://export-locascore-pdf-z5w73fjiva-uc.a.run.app");
    try {
      // Convertir l'objet UserInfo en JSON
      final Map<String, dynamic> tenantMap = tenant.toMapForExport();
      print(tenantMap);

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

        print("Fichier PDF enregistré à : $filePath");

        if (await file.exists()) {
          print("Le fichier existe à l'emplacement : ${file.path}");
          print("Taille du fichier : ${pdfBytes.length} octets");

          final result = await OpenFilex.open(file.path);
          if (result.type == ResultType.done) {
            print("Fichier ouvert avec succès.");
          } else {
            print("Erreur lors de l'ouverture du fichier : ${result.message}");
          }
        } else {
          print("Le fichier n'existe pas, impossible de l'ouvrir.");
        }
      } else {
        print(
            "Erreur lors de la génération du fichier PDF : ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur lors de l'envoi de la requête : $e");
    }
  }

  static Future<void> fetchPostPdf(
    BuildContext context, {
    required String residenceId,
    required String postId,
  }) async {
    final Uri url = Uri.parse(
      "https://europe-west1-connectkasa-84f23.cloudfunctions.net/generate_report",
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
          print("PDF ouvert avec succès.");
        } else {
          print("Erreur à l'ouverture : ${result.message}");
        }
      } else {
        print("Erreur HTTP : ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Erreur lors de l'appel à la Cloud Function : $e");
    }
  }
}
