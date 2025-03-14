import 'package:connect_kasa/controllers/features/line_interaction.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/participed_button.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/event_type.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/pages_vues/event_page_details.dart';
import 'package:connect_kasa/vues/widget_view/header_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventWidget extends StatefulWidget {
  final Post post;
  final String uid;
  final String residenceSelected;
  final Color colorStatut;
  final double scrollController;
  final bool isCsMember;
  final Function updatePostsList;

  const EventWidget(
      {super.key,
      required this.post,
      required this.uid,
      required this.residenceSelected,
      required this.colorStatut,
      required this.scrollController,
      required this.isCsMember,
      required this.updatePostsList});

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget> {
  late Post? updatedPost;
  //bool value = false;

  late Future<List<User?>> participants;
  //late Timestamp _selectedDate;
  DataBasesUserServices dbService = DataBasesUserServices();
  DataBasesPostServices postServices = DataBasesPostServices();
  int userParticipatedCount = 0;

  @override
  void initState() {
    super.initState();
    //_selectedDate = widget.post.eventDate!.toUtc();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
            CustomHeaderRow(
              post: widget.post,
              isCsMember: widget.isCsMember,
              updatePostsList: widget.updatePostsList,
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
                    returnHomePage: true,
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
                  SizedBox(
                    height: 250,
                    width: width,
                    child: Image.network(
                      widget.post.pathImage!,
                      fit: BoxFit.cover,
                    ),
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
          margin: const EdgeInsets.all(12),
          width: 70,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: const BorderRadius.all(Radius.circular(30)),
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
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  color: Colors.black12,
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MyTextStyle.EventDateDay(
                          widget.post.eventDate!, SizeFont.h1.size),
                      MyTextStyle.EventDateMonth(
                          widget.post.eventDate!, SizeFont.h3.size),
                    ]),
              ),
              const SizedBox(
                height: 20,
              ),
              MyTextStyle.lotDesc(
                  MyTextStyle.EventHours(widget.post.eventDate!),
                  SizeFont.h3.size,
                  FontStyle.normal),
              const SizedBox(
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
                MyTextStyle.lotName(
                    widget.post.title, Colors.black87, SizeFont.h2.size),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: MyTextStyle.annonceDesc(
                      widget.post.description, SizeFont.h3.size, 3),
                ),
                const SizedBox(height: 10),
                Visibility(
                  visible: widget.post.eventType!
                      .contains(EventType.evenement.value),
                  child: PartipedTile(
                    sizeFont: SizeFont.h3.size,
                    post: widget.post,
                    residenceSelected: widget.residenceSelected,
                    uid: widget.uid,
                    space: 1,
                    number: 5,
                  ),
                ),
                Visibility(
                  visible: widget.post.eventType!
                      .contains(EventType.prestation.value),
                  child: Row(
                    children: [
                      MyTextStyle.lotName(
                          "Prestataire :", Colors.black87, SizeFont.h2.size),
                      const SizedBox(
                        width: 20,
                      ),
                      MyTextStyle.annonceDesc(
                          widget.post.prestaName ?? "", SizeFont.h3.size, 3),
                    ],
                  ),
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
