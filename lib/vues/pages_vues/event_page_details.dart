import 'package:connect_kasa/controllers/features/line_interaction.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/participed_button.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/pages_vues/my_nav_bar.dart';
import 'package:flutter/material.dart';

class EventPageDetails extends StatefulWidget {
  final Post post;
  final String uid;
  final String residence;
  final Color colorStatut;
  final double scrollController;

  const EventPageDetails({
    super.key,
    required this.post,
    required this.uid,
    required this.residence,
    required this.colorStatut,
    required this.scrollController,
  });

  @override
  State<StatefulWidget> createState() => EventPageDetailsState();
}

class EventPageDetailsState extends State<EventPageDetails> {
  late Future<List<User?>> participants;
  DataBasesUserServices dbService = DataBasesUserServices();
  bool alreadyParticipated = false;
  int userParticipatedCount = 0;
  @override
  void initState() {
    super.initState();
    setState(() {});
    alreadyParticipated = widget.post.participants!.contains(widget.uid);
    userParticipatedCount = widget.post.participants!.length;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.network(
                widget.post.pathImage!,
                fit: BoxFit.cover,
                width: width,
                height: height / 3,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height / 9,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      IconButton(
                        onPressed: () async {
                          // Naviguer vers une nouvelle instance de Homeview pour recharger l'application
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MyNavBar(
                                      uid: widget.uid,
                                      scrollController:
                                          widget.scrollController)));
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ]),
              ),
            ),
            Positioned(
              top: height / 3,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.only(top: 20, left: 20, right: 20),
                    child: MyTextStyle.lotName(
                        widget.post.title, Colors.black87, 25),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    child: Row(children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        width: 1,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.black12),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              child: MyTextStyle.lotName(
                                  MyTextStyle.completDate(
                                      widget.post.timeStamp),
                                  Theme.of(context).primaryColor,
                                  16)),
                          Container(
                              child: MyTextStyle.lotName(
                                  widget.post.location_element,
                                  Colors.black54,
                                  16)),
                        ],
                      ),
                    ]),
                  ),
                  const Divider(
                    thickness: 0.5,
                    color: Colors.black12,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PartipedTile(
                      post: widget.post,
                      residenceSelected: widget.residence,
                      uid: widget.uid,
                      space: 1,
                      number: widget.post.participants!.length,
                    ),
                  ),
                  const Divider(
                    thickness: 0.5,
                    color: Colors.black12,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.only(top: 0, left: 20, bottom: 20),
                        child: MyTextStyle.lotName(
                            "Description", Colors.black87, 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 20),
                        child: MyTextStyle.annonceDesc(
                            widget.post.description, 14, 15),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IteractionLine(widget.post, widget.residence, widget.uid,
                    widget.colorStatut))
          ],
        ),
      ),
    );
  }
}
