import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connect_kasa/core/utils/app_logger.dart';

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

  static dynamic launchEmail(String mail, String userContact) async {
    String subject =
        ("$userContact vous contact depuis son espace ConnectKasa");

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
