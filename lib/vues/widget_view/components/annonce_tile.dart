import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/pages_vues/annonces_page/annonce_page_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnnonceTile extends StatelessWidget {
  final Post post;
  final String uid;
  final String residence;
  final bool canModify;
  final Color colorStatut;
  final double scrollController;

  const AnnonceTile(this.post, this.residence, this.uid, this.canModify,
      this.colorStatut, this.scrollController,
      {super.key});

  @override
  Widget build(BuildContext context) {
    String pathImage = post.pathImage ?? "pas d'image";
    String title = post.title;
    String desc = post.description;
    String subtype = post.subtype ?? "N/A";
    String price = post.setPrice(post.price);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (context) => AnnoncePageDetails(
            returnHomePage: false,
            post: post,
            uid: uid,
            residence: residence,
            colorStatut: colorStatut,
            scrollController: scrollController,
          ),
        ));
      },
      child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                child: SizedBox(
                  height: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          height: 115,
                          width: MediaQuery.of(context).size.width / 2,
                          // Wrap Row with SizedBox to provide a fixed height
                          // Specify the desired height
                          child: pathImage != "" && pathImage.isNotEmpty
                              ? Image.network(
                                  pathImage,
                                  fit: BoxFit.cover,
                                )
                              : imageAnnounced(context, 140, 140),
                        ),
                      ),
                      SizedBox(
                          height: 30,
                          child: MyTextStyle.lotName(
                              title, Colors.black87, SizeFont.h2.size)),
                      MyTextStyle.annonceDesc(subtype, SizeFont.h3.size, 2),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: SizedBox(
                            height: 60,
                            child: MyTextStyle.annonceDesc(
                                desc, SizeFont.h3.size, 2)),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 5),
                            child: MyTextStyle.lotDesc(
                                "Prix :",
                                SizeFont.h3.size,
                                FontStyle.italic,
                                FontWeight.w900),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: MyTextStyle.lotDesc(price, SizeFont.h3.size,
                                FontStyle.italic, FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
