import 'package:konodal/models/enum/font_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/controllers/features/contact_features.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/models/pages_models/contact.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class DetailContactView extends ConsumerWidget {
  final Contact contact;
  final String uid;

  const DetailContactView(
      {super.key, required this.contact, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            "Détails du contact", Colors.black87, SizeFont.h1.size),
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: AppLoader(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        data: (userContact) {
          return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MyTextStyle.lotName(
                            contact.name, Colors.black87, SizeFont.h2.size),
                        const SizedBox(height: 15),
                        const Divider(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (contact.address.street.isNotEmpty &&
                                contact.address.city.isNotEmpty)
                              InkWell(
                                onTap: () => ContactFeatures.openMaps(
                                    "${contact.address.street}, ${contact.address.zipCode} ${contact.address.city}"),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 30),
                                          child: const Icon(Icons.place),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            MyTextStyle.lotDesc(
                                                contact.address.street,
                                                SizeFont.h3.size),
                                            MyTextStyle.lotDesc(
                                                "${contact.address.zipCode} ${contact.address.city}",
                                                SizeFont.h3.size),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
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
                                        MyTextStyle.lotDesc(
                                            contact.phone, SizeFont.h3.size),
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
                                        MyTextStyle.lotDesc(
                                            contact.mail!,
                                            SizeFont.h3
                                                .size), // Change to appropriate text
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
                                        MyTextStyle.lotDesc(
                                            contact.web!,
                                            SizeFont.h3
                                                .size), // Change to appropriate text
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
        },
      ),
    );
  }
}
