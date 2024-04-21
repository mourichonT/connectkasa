import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/widgets_controllers/buid_google_map.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/services/databases_mail_services.dart';
import 'package:connect_kasa/models/pages_models/mail.dart';
import 'package:intl/intl.dart';

class CardContactView extends StatefulWidget {
  final String accountantName;
  final String accountantSurname;
  final String accountantPhone;
  final String agencyName;
  final String agencystreet;
  final String agencyNum;
  final String agencyVoie;
  final String agencyZIPCode;
  final String agencyCity;
  final String uid;

  CardContactView({
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
  });

  @override
  _CardContactViewState createState() => _CardContactViewState();
}

class _CardContactViewState extends State<CardContactView> {
  late Future<List<Mail>> _mailsFuture;
  DatabasesMailServices _databasesMail = DatabasesMailServices();

  @override
  void initState() {
    super.initState();
    _mailsFuture = _databasesMail.getMailFromUid(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final address =
        '${widget.agencyNum} ${widget.agencyVoie} ${widget.agencystreet}, ${widget.agencyZIPCode} ${widget.agencyCity}';

    return FutureBuilder<List<Mail>>(
      future: _mailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
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
                      padding: EdgeInsets.all(16),
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${widget.agencyName}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (mails.isNotEmpty) // Add this condition
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(top: 20),
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: 300, // Set fixed height
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: ListView.separated(
                          itemCount: mails.length,
                          itemBuilder: (context, index) {
                            return Container(
                              child: ListTile(
                                title: MyTextStyle.MailDate(
                                    mails[index].startTime),
                                subtitle: Text(
                                  mails[index].html,
                                  overflow: TextOverflow
                                      .ellipsis, // Gérer le dépassement de texte
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => Divider(
                            thickness: 0.3,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: mails.isNotEmpty ? 320 : 60,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(top: 20),
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    // Call action
                                  },
                                  child: Row(
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
                                    // Message action
                                  },
                                  child: Row(
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
                                  padding: EdgeInsets.all(16),
                                  child: Icon(Icons.location_on),
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
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "${widget.agencyVoie} ",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "${widget.agencystreet} ",
                                          style: TextStyle(
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
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "${widget.agencyCity} ",
                                          style: TextStyle(
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
                          Container(
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
                                        TextSpan(
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
                                              // Action when "ici" is clicked
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
