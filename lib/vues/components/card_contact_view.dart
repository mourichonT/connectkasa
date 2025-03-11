import 'package:connect_kasa/controllers/features/contact_features.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/widgets_controllers/buid_google_map.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/components/modal_entry_text.dart';
import 'package:connect_kasa/vues/pages_vues/mail_chat_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/services/databases_mail_services.dart';
import 'package:connect_kasa/models/pages_models/mail.dart';

class CardContactView extends StatefulWidget {
  final Lot selectedlot;
  final String accountantFonction;
  final String accountantName;
  final String accountantSurname;
  final String accountantPhone;
  final String accountantMail;
  final String agencyName;
  final String agencystreet;
  final String agencyNum;
  final String agencyVoie;
  final String agencyZIPCode;
  final String agencyCity;
  final String uid;
  final String accountantId;

  const CardContactView({super.key, 
    required this.selectedlot,
    required this.accountantName,
    required this.accountantSurname,
    required this.accountantPhone,
    required this.agencyName,
    required this.agencystreet,
    required this.agencyNum,
    required this.agencyVoie,
    required this.agencyZIPCode,
    required this.agencyCity,
    required this.uid,
    required this.accountantMail,
    required this.accountantFonction,
    required this.accountantId,
  });

  @override
  _CardContactViewState createState() => _CardContactViewState();
}

class _CardContactViewState extends State<CardContactView> {
  late Future<List<Mail>> _mailsFuture;
  final DatabasesMailServices _databasesMail = DatabasesMailServices();

  @override
  void initState() {
    super.initState();
    // _mailsFuture = _databasesMail.getMailFromUid(widget.uid);
    _mailsFuture = _databasesMail.getMailFromUid(
        widget.uid, widget.selectedlot, widget.accountantMail);
  }

  @override
  Widget build(BuildContext context) {
    final address =
        '${widget.agencyNum} ${widget.agencyVoie} ${widget.agencystreet}, ${widget.agencyZIPCode} ${widget.agencyCity}';

    return FutureBuilder<List<Mail>>(
      future: _mailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Erreur : ${snapshot.error}'),
          );
        } else {
          List<Mail> mails = snapshot.data ?? [];

          return SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.agencyName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            widget.accountantFonction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (mails.isNotEmpty) // Add this condition
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MailChatPage(
                                        selectedLot: widget.selectedlot,
                                        agencyName: widget.agencyName,
                                        mails: mails,
                                        to: [widget.accountantMail],
                                        uid: widget.uid,
                                      )));
                        },
                        child: Container(
                          padding: const EdgeInsets.only(top: 20),
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: SizedBox(
                                  width: 30, // Set a specific width
                                  child: mails.last.from != null
                                      ? const Icon(Icons
                                          .subdirectory_arrow_right_rounded)
                                      : Container(),
                                ),
                                title:
                                    MyTextStyle.MailDate(mails.last.startTime),
                                subtitle: Text(
                                  mails.last.html,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: mails.isNotEmpty ? 170 : 90,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.only(top: 20),
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Divider(
                            thickness: 0.3,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    ContactFeatures.launchPhoneCall(
                                        widget.accountantPhone);
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 14,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text("Appeler"),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MailChatPage(
                                                  selectedLot:
                                                      widget.selectedlot,
                                                  agencyName: widget.agencyName,
                                                  mails: mails,
                                                  to: [widget.accountantMail],
                                                  uid: widget.uid,
                                                )));
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.mail,
                                        size: 14,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text("Message"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: const Icon(Icons.location_on),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${widget.agencyNum} ",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "${widget.agencyVoie} ",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "${widget.agencystreet} ",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "${widget.agencyZIPCode} ",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "${widget.agencyCity} ",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height:
                                200, // Taille fixe pour la carte Google Maps
                            child: AgencyMapWidget(
                              address: address,
                              agencyName: widget.agencyName,
                            ),
                          ),
                          Container(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text:
                                              "Vous constatez un changement de coordonnée, merci de nous le faire savoir en cliquant ",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        TextSpan(
                                          text: "ici",
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              showModalBottomSheet(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return TextEntryModal(
                                                    onSave: (String text) {
                                                      // Faites quelque chose avec le texte ici, par exemple, envoyez-le à une fonction ou mettez-le dans une variable.
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
