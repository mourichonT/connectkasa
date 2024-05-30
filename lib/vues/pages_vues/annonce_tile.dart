import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:connect_kasa/vues/pages_vues/annonce_page_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AnnonceTile extends StatefulWidget {
  late Post post;
  final String uid;
  final String residence;
  final bool canModify;
  final Color colorStatut;
  final double scrollController;

  AnnonceTile(this.post, this.residence, this.uid, this.canModify,
      this.colorStatut, this.scrollController);

  @override
  State<StatefulWidget> createState() => AnnonceTileState();
}

class AnnonceTileState extends State<AnnonceTile> {
  late Future<List<Post>> _signalementFuture;
  DataBasesPostServices dbService = DataBasesPostServices();
  final DataBasesUserServices databasesUserServices = DataBasesUserServices();

  int postCount = 0;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _signalementFuture =
        dbService.getSignalements(widget.residence, widget.post.id);
    _loadSignalements();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _loadSignalements() async {
    final signalements =
        await dbService.getSignalements(widget.residence, widget.post.id);
    if (_isMounted) {
      setState(() {
        postCount = signalements.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _signalementFuture,
      builder: (context, snapshot) {
        if (_isMounted) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Post> signalements = snapshot.data!;
            postCount = signalements.length;
            String pathImage = signalements[0].pathImage ?? "pas d'image";
            String title = signalements[0].title ?? "N/A";
            String desc = signalements[0].description ?? "N/A";
            String subtype = signalements[0].subtype ?? "N/A";
            String price =
                signalements[0].setPrice(signalements[0].price) ?? "N/A";
            return InkWell(
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => AnnoncePageDetails(
                    returnHomePage: false,
                    post: signalements[0],
                    uid: widget.uid,
                    residence: widget.residence,
                    colorStatut: widget.colorStatut,
                    scrollController: widget.scrollController,
                  ),
                ));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          height: 120,
                          width: MediaQuery.of(context).size.width / 2,
                          // Wrap Row with SizedBox to provide a fixed height
                          // Specify the desired height
                          child: pathImage != "" &&
                                  pathImage != null &&
                                  pathImage.isNotEmpty
                              ? Image.network(
                                  pathImage,
                                  fit: BoxFit.cover,
                                )
                              : ImageAnnounced(context, 140, 140),
                        ),
                      ),
                      Container(
                          height: 30,
                          child: MyTextStyle.lotName(title, Colors.black87)),
                      MyTextStyle.annonceDesc(subtype, 11, 2),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: MyTextStyle.annonceDesc(desc, 13, 2),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 5),
                            child: MyTextStyle.lotDesc("Prix :", 13,
                                FontStyle.italic, FontWeight.w900),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: MyTextStyle.lotDesc(
                                price, 13, FontStyle.italic, FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        } else {
          return SizedBox(); // Return a widget with no size if the widget is not mounted
        }
      },
    );
  }
}
