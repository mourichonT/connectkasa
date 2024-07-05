// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/contact.dart';
import 'package:connect_kasa/vues/pages_vues/detail_contact_view.dart';
import 'package:connect_kasa/vues/pages_vues/emergencies_contact_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContactView extends StatelessWidget {
  final String uid;
  final String residenceSelected;
  final String residenceName;
  final DataBasesResidenceServices _databaseContactServices =
      DataBasesResidenceServices();
  late Future<List<Contact>> _allContactsFuture;

  ContactView(
      {super.key,
      required this.residenceSelected,
      required this.residenceName,
      required this.uid});

  @override
  Widget build(BuildContext context) {
    _allContactsFuture =
        _databaseContactServices.getContactByResidence(residenceSelected);

    return FutureBuilder<List<Contact>>(
        future: _allContactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Affichez un indicateur de chargement si les données ne sont pas encore disponibles
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            // Gérez les erreurs ici
            return Text('Error: ${snapshot.error}');
          } else {
            List<Contact> allContact = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
                title: Container(
                    child: MyTextStyle.lotName(
                        'Numéros utiles du $residenceName',
                        Colors.black87,
                        SizeFont.h1.size)),
              ),
              body: SingleChildScrollView(
                child: Column(children: [
                  ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: allContact.length,
                      itemBuilder: (context, index) {
                        Contact contact = allContact[index];
                        return Material(
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) => DetailContactView(
                                          contact: contact,
                                          uid: uid,
                                        )),
                              );
                            },
                            leading: SizedBox(
                                width: MediaQuery.of(context).size.width / 4,
                                child: MyTextStyle.lotName(contact.service,
                                    Colors.black87, SizeFont.h3.size)),
                            title: MyTextStyle.lotName(
                                contact.name, Colors.black87, SizeFont.h3.size),
                            subtitle: MyTextStyle.lotDesc(
                                contact.phone, SizeFont.h3.size),
                            trailing: const Icon(
                              Icons.arrow_right,
                              size: 35,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider()),
                  EmergenciesContactsView(),
                ]),
              ),
            );
          }
        });
  }
}
