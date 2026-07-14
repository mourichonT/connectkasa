import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:konodal/core/utils/app_logger.dart';

class ContactFeatures {
  static void launchPhoneCall(String phoneNumber) async {
    Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static void openUrl(String urlSource) async {
    Uri url = Uri.parse(urlSource);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Recherche Google Maps (pas un lien geo:) : ouvre l'app Maps si
  // installée, sinon un navigateur - contrairement à geo:, fonctionne de
  // façon cohérente sur Android et iOS sans configuration supplémentaire.
  static void openMaps(String address) async {
    Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static dynamic launchEmail(String mail, String userContact) async {
    String subject =
        ("$userContact vous contact depuis son espace KONODAL");

    try {
      Uri email = Uri(
        scheme: 'mailto',
        path: mail,
        queryParameters: {
          'subject': subject,
        },
      );
      appLog("queryParameters: ${email.queryParameters}");
      await launchUrl(email);
    } catch (e) {
      appLog(e.toString());
    }
  }

  static void openPdfFile(BuildContext context, url, String? name) {}
}
