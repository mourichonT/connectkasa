import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/material.dart';

class SignalementTile extends StatelessWidget {
  final Post post;
  final double width;

  SignalementTile(this.post, this.width);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: width / 1.5,
                width: width,
                child: Image.network(
                  post.pathImage ?? "pas d'image",
                  fit: BoxFit.fill,
                )
                //Image.asset(post.pathImage ?? "placeholder_image_path", fit: BoxFit.fitWidth,)
                ),
            Container(
                //decoration: BoxDecoration(color: Colors.blue),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyTextStyle.lotName(post.title, Colors.black87),
                      Row(
                        children: [
                          MyTextStyle.lotName(
                              "Localisation : ", Colors.black54),
                          MyTextStyle.lotName(post.emplacement, Colors.black54),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      MyTextStyle.lotDesc(post.description),
                      SizedBox(
                        height: 15,
                      ),
                    ])),
          ],
        ),
        onTap: () {
          print("je test Inkell");
        });
  }
}
