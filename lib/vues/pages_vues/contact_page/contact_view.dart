// ignore_for_file: must_be_immutable

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/contact_providers.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/contact.dart';
import 'package:konodal/vues/pages_vues/contact_page/detail_contact_view.dart';
import 'package:konodal/vues/pages_vues/contact_page/emergencies_contact_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

// Icône par catégorie de prestation (cf. TypeList.servicePrestaList, liste
// fermée utilisée par manage_contact.dart) - contact_phone_outlined en repli
// pour un service non reconnu.
IconData _iconForService(String service) {
  switch (service) {
    case "Nettoyage":
      return Icons.cleaning_services_outlined;
    case "Espaces verts":
      return Icons.grass_outlined;
    case "Électricité":
      return Icons.bolt_outlined;
    case "Entretiens Ascenseur":
      return Icons.elevator_outlined;
    case "Chauffage collectif":
      return Icons.thermostat_outlined;
    case "Plomberie":
      return Icons.plumbing_outlined;
    case "Ventilation (VMC)":
      return Icons.air_outlined;
    case "Portes et portails":
      return Icons.sensor_door_outlined;
    case "Vidéosurveillance":
      return Icons.videocam_outlined;
    case "Sécurité incendie":
      return Icons.local_fire_department_outlined;
    case "Gestion administrative":
      return Icons.folder_outlined;
    case "Toiture / étanchéité":
      return Icons.roofing_outlined;
    default:
      return Icons.contact_phone_outlined;
  }
}

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
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 20, right: 30),
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
                      leading: Icon(_iconForService(contact.service)),
                      title: MyTextStyle.lotName(
                          contact.name, Colors.black87, SizeFont.h3.size),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (contact.service.isNotEmpty)
                            MyTextStyle.lotDesc(
                                contact.service, SizeFont.h3.size),
                          MyTextStyle.lotDesc(contact.phone, SizeFont.h3.size),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF757575),
                        size: 22,
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
