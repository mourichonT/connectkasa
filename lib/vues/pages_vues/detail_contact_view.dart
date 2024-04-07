import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/contact_features.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/contact.dart';

import '../../models/pages_models/user.dart';

class DetailContactView extends StatelessWidget {
  final Contact contact;
  final String uid;

  const DetailContactView({Key? key, required this.contact, required this.uid})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName("Détails du contact", Colors.black87),
      ),
      body: FutureBuilder(
        future: DataBasesUserServices().getUserById(uid),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              final userContact = snapshot.data;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MyTextStyle.lotName(contact.name, Colors.black87),
                        const SizedBox(height: 15),
                        if (contact.num != "" &&
                            contact.street != "" &&
                            contact.city != "")
                          InkWell(
                            onTap: () {},
                            //focusColor: Colors.green,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 30),
                                  child: const Icon(Icons.place),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    MyTextStyle.lotDesc(
                                        "${contact.num} ${contact.street}", 14),
                                    MyTextStyle.lotDesc(
                                        "${contact.zipcode} ${contact.city}",
                                        14),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(
                          height: 15,
                        ),
                        const Divider(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (contact.phone != "")
                              InkWell(
                                onTap: () {
                                  ContactFeatures.launchPhoneCall(
                                      contact.phone);
                                },
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 30),
                                          child: const Icon(Icons.call),
                                        ),
                                        const SizedBox(width: 10),
                                        MyTextStyle.lotDesc(contact.phone, 14),
                                      ],
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            if (contact.mail != "" && userContact != null)
                              InkWell(
                                onTap: () {
                                  ContactFeatures.launchEmail(contact.mail!,
                                      "${userContact.name} ${userContact.surname}");
                                },
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 30),
                                          child: const Icon(
                                              Icons.mail_outline_outlined),
                                        ),
                                        const SizedBox(width: 10),
                                        MyTextStyle.lotDesc(contact.mail!,
                                            14), // Change to appropriate text
                                      ],
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            if (contact.web != "")
                              InkWell(
                                onTap: () {
                                  ContactFeatures.openUrl(contact.web!);
                                },
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 30),
                                          child: const Icon(Icons.language),
                                        ),
                                        const SizedBox(width: 10),
                                        MyTextStyle.lotDesc(contact.web!,
                                            14), // Change to appropriate text
                                      ],
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          }
        },
      ),
    );
  }
}
