import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:flutter/material.dart';

class AnnuoncedTile2 extends StatefulWidget {
  late Post post;
  final String uid;
  final String residence;
  final bool canModify;

  AnnuoncedTile2(this.post, this.residence, this.uid, this.canModify);

  @override
  State<StatefulWidget> createState() => AnnuoncedTileState();
}

class AnnuoncedTileState extends State<AnnuoncedTile2> {
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
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.symmetric(vertical: 0.5),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              child: FutureBuilder<List<Post>>(
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
                      String pathImage =
                          signalements[0].pathImage ?? "pas d'image";
                      String title = signalements[0].title;
                      String desc = signalements[0].description;
                      Timestamp timeStamp = signalements[0].timeStamp;
                      late Future<User?> userPost = databasesUserServices
                          .getUserById(signalements[0].user);
                      return Row(
                        children: [
                          if (pathImage != null && pathImage.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(35.0),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                width: 110,
                                height: 140,
                                child: pathImage != ""
                                    ? Image.network(
                                        pathImage,
                                        fit: BoxFit.cover,
                                      )
                                    : ImageAnnounced(context, 140, 140),
                              ),
                            ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<User?>(
                                    future: userPost,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        var user = snapshot.data;
                                        if (user != null) {
                                          return MyTextStyle.postDesc(
                                            user.pseudo ??
                                                "Pseudo indisponible",
                                            14,
                                            Colors.black87,
                                          );
                                        } else {
                                          return Text("Utilisateur non trouvé");
                                        }
                                      }
                                    }),
                                SizedBox(
                                  height: 10,
                                ),
                                MyTextStyle.lotName(title, Colors.black87),
                                MyTextStyle.annonceDesc(desc, 16, 2),
                                Divider(),
                                MyTextStyle.postDate(timeStamp)
                              ],
                            ),
                          )
                        ],
                      );
                    }
                  } else {
                    return SizedBox(); // Retourner un widget vide si le widget n'est pas monté
                  }
                },
              ),
            ),
          ),
          if (widget.canModify)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(onPressed: () {}, child: Icon(Icons.edit)),
                  SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(onPressed: () {}, child: Icon(Icons.delete)),
                ],
              ),
            )
        ],
      ),
    );
  }
}
