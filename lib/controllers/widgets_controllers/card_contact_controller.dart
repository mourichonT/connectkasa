// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_agency_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/components/card_contact_view.dart';
import 'package:flutter/material.dart';

class CardContactController extends StatelessWidget {
  final String? refGerance;
  final Lot selectedlot;
  final String? dept;
  final String uid;

  CardContactController(this.selectedlot, this.dept,
      {super.key, required this.uid, this.refGerance});

  final DatabasesAgencyServices _databasesAgency = DatabasesAgencyServices();
  @override
  Widget build(BuildContext context) {
    final choiceDept = (dept == "serviceSyndic")
        ? selectedlot.residenceData["refGerance"]
        : selectedlot.refGerance;
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
        future: _databasesAgency.getDeptByRefId(choiceDept, dept!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Retourner un indicateur de chargement pendant la récupération de l'agence
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Gérer l'erreur si la récupération de l'agence échoue
            return const Center(
                child: Text('Erreur lors de la récupération de l\'agence'));
          } else {
            // Une fois l'agence récupérée, afficher son nom
            final documents = snapshot.data;
            if (documents != null && documents.isNotEmpty) {
              // Supposons que le nom et le prénom de l'agence sont stockés dans le premier document
              final accountantData = documents.first.data();
              final agencyData = documents.last.data();
              final accountantName = accountantData?['name'] ?? '';
              final accountantId = accountantData?['id'] ?? '';
              final accountantSurname = accountantData?['surname'] ?? '';
              final accountantPhone = accountantData?['phone'] ?? '';
              final accountantMail = accountantData?['mail'] ?? '';
              final accountantFonction = accountantData?['fonction'] ?? '';
              final agencyName = agencyData?['name'] ?? '';
              final agencystreet = agencyData?['street'] ?? '';
              final agencyNum = agencyData?['numeros'] ?? '';
              final agencyVoie = agencyData?['voie'] ?? '';
              final agencyZIPCode = agencyData?['zipCode'] ?? '';
              final agencyCity = agencyData?['city'] ?? '';

              return CardContactView(
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
              );
            } else {
              // Gérer le cas où l'agence est null ou vide
              return const Center(child: Text('Agence introuvable'));
            }
          }
        },
      ),
    );
  }
}
