// ignore_for_file: must_be_immutable

import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/components/card_contact_view.dart';
import 'package:flutter/material.dart';

class CardContactController extends StatelessWidget {
  final Lot selectedlot;
  final String? dept;
  final String uid;

  CardContactController(
    this.selectedlot,
    this.dept, {
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? agencyData;
    List<dynamic>? agents;
    print(dept);
    if (dept == "serviceSyndic") {
      // On prend directement les données depuis residenceData
      agencyData = selectedlot.residenceData['syndicAgency'];
    } else if (dept == "geranceLocative") {
      // On prend les données depuis syndicAgency
      agencyData = {};
    }

    if (agencyData == null) {
      return const Center(child: Text('Agence introuvable'));
    }

    agents = agencyData['agents'] ?? [];

    // On récupère le premier agent comme comptable
    final accountant = agents!.isNotEmpty ? agents.first : {};
    final accountantName = accountant['name_agent'] ?? '';
    final accountantSurname = accountant['surname_agent'] ?? '';
    final accountantPhone = agencyData['syndic']['phone'] ?? '';
    final accountantMail = agencyData['syndic']['mail'] ?? '';
    final accountantFonction = 'syndic'; // Ou une valeur par défaut

    final agencyName = agencyData['name'] ?? '';
    final agencystreet = agencyData['street'] ?? '';
    final agencyNum = agencyData['numeros'] ?? '';
    final agencyVoie = agencyData['voie'] ?? '';
    final agencyZIPCode = agencyData['zipCode'] ?? '';
    final agencyCity = agencyData['city'] ?? '';
    final accountantId = agencyData['id'] ?? '';

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: CardContactView(
        selectedlot: selectedlot,
        accountantName: accountantName,
        accountantSurname: accountantSurname,
        accountantPhone: accountantPhone,
        accountantMail: accountantMail,
        accountantFonction: accountantFonction,
        agencyName: agencyName,
        agencystreet: agencystreet,
        agencyNum: agencyNum,
        agencyVoie: agencyVoie,
        agencyZIPCode: agencyZIPCode,
        agencyCity: agencyCity,
        uid: uid,
        accountantId: accountantId,
      ),
    );
  }
}
