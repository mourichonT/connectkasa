import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  final Post post;
  final String uid;
  final String residence;

  EventTile(
      {super.key,
      required this.post,
      required this.uid,
      required this.residence});

  DataBasesPostServices dbService = DataBasesPostServices();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 10),
      width: MediaQuery.of(context).size.width * 0.95,
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (post.pathImage != "" &&
                post.pathImage != null &&
                post.pathImage!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(35.0),
                child: Container(
                  padding: EdgeInsets.all(8),
                  width: 120,
                  height: 120,
                  child: Image.network(
                    post.pathImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(35.0),
                child: Container(
                  padding: EdgeInsets.all(8),
                  width: 120,
                  height: 120,
                  child: ImageAnnounced(context, 120, 120),
                ),
              ),
            Container(
              width: MediaQuery.of(context).size.width / 1.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyTextStyle.lotName(MyTextStyle.completDate(post.eventDate!),
                      Colors.black87, SizeFont.h3.size),
                  MyTextStyle.lotDesc(
                      post.title, SizeFont.h3.size, FontStyle.normal),
                  MyTextStyle.annonceDesc(
                      post.description, SizeFont.h3.size, 2),
                ],
              ),
            )
          ])
        ],
      ),
    );
  }
}
