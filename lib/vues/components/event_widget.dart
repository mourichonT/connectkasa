import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/line_interaction.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/participed_button.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/pages_vues/event_page_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventWidget extends StatefulWidget {
  final Post post;
  final String uid;
  final String residenceSelected;
  final Color colorStatut;
  final double scrollController;

  const EventWidget({
    required this.post,
    required this.uid,
    required this.residenceSelected,
    required this.colorStatut,
    required this.scrollController,
  });

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget> {
  late Post? updatedPost;
  //bool value = false;

  late Future<List<User?>> participants;
  late Timestamp _selectedDate;
  DataBasesUserServices dbService = DataBasesUserServices();
  DataBasesPostServices postServices = DataBasesPostServices();
  int userParticipatedCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.post.timeStamp;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 1, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  MyTextStyle.lotName(getType(widget.post), Colors.black87),
                  const SizedBox(width: 15),
                  const Spacer(),
                ],
              ),
            ),
            const Divider(
              height: 20,
              thickness: 0.5,
            ),
            InkWell(
              onTap: () async {
                updatedPost = await postServices.getUpdatePost(
                    widget.residenceSelected, widget.post.id);

                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => EventPageDetails(
                    post: updatedPost!,
                    uid: widget.uid,
                    residence: widget.residenceSelected,
                    colorStatut: widget.colorStatut,
                    scrollController: widget.scrollController,

                    // alreadyParticipated: alreadyParticipated,
                  ),
                ));
              },
              child: Column(
                children: [
                  Image.network(
                    widget.post.pathImage!,
                    fit: BoxFit.cover,
                  ),
                  buildListTile(),
                ],
              ),
            ),
            IteractionLine(widget.post, widget.residenceSelected, widget.uid,
                widget.colorStatut)
          ],
        ),
      ),
    );
  }

  Widget buildListTile() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.all(12),
          width: 70,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.all(Radius.circular(30)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  color: Colors.black12,
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MyTextStyle.EventDateDay(_selectedDate, 21),
                      MyTextStyle.EventDateMonth(_selectedDate, 16),
                    ]),
              ),
              SizedBox(
                height: 20,
              ),
              MyTextStyle.EventHours(_selectedDate, 16),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                MyTextStyle.lotName(widget.post.title, Colors.black87),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child:
                      MyTextStyle.annonceDesc(widget.post.description, 14, 3),
                ),
                const SizedBox(height: 10),
                PartipedTile(
                  post: widget.post,
                  residenceSelected: widget.residenceSelected,
                  uid: widget.uid,
                  space: 1,
                  number: 5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<List<String>> typeList = TypeList().typeDeclaration();

  String getType(Post post) {
    for (var type in typeList) {
      var typeName = type[0];
      var typeValue = type[1];
      if (post.type == typeValue) {
        return typeName;
      }
    }
    return '';
  }
}
