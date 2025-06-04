// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/contact_features.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/contact.dart';
import 'package:flutter/material.dart';

class EmergenciesContactsView extends StatelessWidget {
  final DataBasesResidenceServices _databaseContactServices =
      DataBasesResidenceServices();
  late Future<List<Contact>> allEmergenciesContactsFuture;

  EmergenciesContactsView({super.key});
  @override
  Widget build(BuildContext context) {
    allEmergenciesContactsFuture =
        _databaseContactServices.getEmergenciesContacts();
    return FutureBuilder<List<Contact>>(
        future: allEmergenciesContactsFuture,
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
            List<Contact> allEmergenciesContact = snapshot.data!;
            return Column(
              children: [
                const SizedBox(
                  height: 15,
                ),
                Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(color: Colors.black12),
                    child: Center(
                      child: MyTextStyle.lotName("Contacts d'urgence",
                          Colors.black87, SizeFont.h2.size),
                    )),
                const SizedBox(
                  height: 15,
                ),
                ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: allEmergenciesContact.length,
                    itemBuilder: (context, index) {
                      Contact contact = allEmergenciesContact[index];
                      return Material(
                        child: ListTile(
                          onTap: () {},
                          leading: SizedBox(
                              width: MediaQuery.of(context).size.width / 4,
                              child: MyTextStyle.lotName(contact.service,
                                  Colors.black87, SizeFont.h3.size)),
                          title:
                              MyTextStyle.lotName(contact.name, Colors.black87),
                          subtitle: MyTextStyle.lotDesc(
                              contact.phone, SizeFont.h3.size),
                          trailing: IconButton(
                            icon: const Icon(Icons.call),
                            onPressed: () {
                              ContactFeatures.launchPhoneCall(contact.phone);
                            },
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: const Divider(),
                        ))
              ],
            );
          }
        });
  }
}
