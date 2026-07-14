import 'package:konodal/controllers/features/contact_features.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/widgets_controllers/buid_google_map.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/modal_entry_text.dart';
import 'package:konodal/vues/pages_vues/chat_page/mail_chat_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:konodal/core/repositories/firestore_mail_repository.dart';
import 'package:konodal/models/pages_models/mail.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class CardContactView extends StatefulWidget {
  final Lot selectedlot;
  final String accountantFonction;
  final String accountantName;
  final String accountantSurname;
  final String accountantPhone;
  final String accountantMail;
  final String agencyName;
  final String agencystreet;
  final String agencyZIPCode;
  final String agencyCity;
  final String uid;
  final String accountantId;

  const CardContactView({
    super.key,
    required this.selectedlot,
    required this.accountantName,
    required this.accountantSurname,
    required this.accountantPhone,
    required this.agencyName,
    required this.agencystreet,
    required this.agencyZIPCode,
    required this.agencyCity,
    required this.uid,
    required this.accountantMail,
    required this.accountantFonction,
    required this.accountantId,
  });

  @override
  State<CardContactView> createState() => _CardContactViewState();
}

class _CardContactViewState extends State<CardContactView> {
  late Future<List<Mail>> _mailsFuture;
  final FirestoreMailRepository _mailRepository = FirestoreMailRepository();

  @override
  void initState() {
    super.initState();
    _fetchMails();
  }

  void _fetchMails() {
    _mailsFuture = _mailRepository
        .getMailFromUid(widget.uid, widget.selectedlot, widget.accountantMail)
        .then((result) =>
            result.when(success: (mails) => mails, failure: (error) => throw error));
  }

  Future<void> _openMailChat(BuildContext context, List<Mail> mails) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MailChatPage(
                  selectedLot: widget.selectedlot,
                  agencyName: widget.agencyName,
                  mails: mails,
                  to: [widget.accountantMail],
                  uid: widget.uid,
                )));
    // Un nouveau message peut avoir été envoyé depuis MailChatPage : sans ce
    // rafraîchissement, l'aperçu du dernier message reste figé sur l'état
    // d'avant l'envoi au retour sur cet écran.
    if (mounted) setState(_fetchMails);
  }

  @override
  Widget build(BuildContext context) {
    final address =
        '${widget.agencystreet}, ${widget.agencyZIPCode} ${widget.agencyCity}';

    return FutureBuilder<List<Mail>>(
      future: _mailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: AppLoader(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Erreur : ${snapshot.error}'),
          );
        } else {
          List<Mail> mails = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.4),
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
                if (mails.isNotEmpty)
                  InkWell(
                    onTap: () => _openMailChat(context, mails),
                    child: Container(
                      padding: const EdgeInsets.only(top: 20),
                      color: Colors.white,
                      child: ListTile(
                        leading: SizedBox(
                          width: 30, // Set a specific width
                          child: mails.last.from != null
                              ? const Icon(
                                  Icons.subdirectory_arrow_right_rounded)
                              : Container(),
                        ),
                        title: MyTextStyle.mailDate(mails.last.startTime),
                        subtitle: Text(
                          mails.last.html,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.only(top: 20),
                  color: Colors.white,
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
                              onPressed: () => _openMailChat(context, mails),
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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
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
                        height: 200, // Taille fixe pour la carte Google Maps
                        child: AgencyMapWidget(
                          address: address,
                          agencyName: widget.agencyName,
                        ),
                      ),
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
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
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
          );
        }
      },
    );
  }
}
