// ignore_for_file: must_be_immutable

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/residence_providers.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/contact.dart';
import 'package:konodal/vues/pages_vues/contact_page/detail_contact_view.dart';
import 'package:konodal/vues/pages_vues/contact_page/emergencies_contact_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class ContactView extends ConsumerWidget {
  final String uid;
  final String residenceSelected;
  final String residenceName;

  const ContactView(
      {super.key,
      required this.residenceSelected,
      required this.residenceName,
      required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsByResidenceProvider(residenceSelected));

    return contactsAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Text('Error: $error'),
      data: (allContact) {
        return Scaffold(
          appBar: AppBar(
            title: Container(
                child: MyTextStyle.lotName('Numéros utiles du $residenceName',
                    Colors.black87, SizeFont.h1.size)),
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
                          Icons.arrow_forward_ios,
                          color: Color(0xFF757575),
                          size: 22,
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: const Divider(),
                      )),
              EmergenciesContactsView(),
            ]),
          ),
        );
      },
    );
  }
}
