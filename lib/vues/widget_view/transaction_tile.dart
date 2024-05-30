import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/services/transaction_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/transaction.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:flutter/material.dart';

class TransactionTile extends StatefulWidget {
  final TransactionModel transac;
  final String residence;
  final String uid;

  const TransactionTile(this.transac, this.residence, this.uid, {super.key});

  @override
  State<StatefulWidget> createState() => TransactionTileState();
}

class TransactionTileState extends State<TransactionTile> {
  final TransactionServices ts = TransactionServices();
  final DataBasesPostServices postData = DataBasesPostServices();
  //late Future<List<TransactionModel>> _transacFuture;
  late Future<Post> post;

  final DataBasesUserServices databasesUserServices = DataBasesUserServices();
  late Future<User?> userAcheteur;
  late Future<User?> userVendeur;

  @override
  void initState() {
    post = postData.getPost(
      widget.residence,
      widget.transac.postId,
    );
    // TODO: implement initState

    userAcheteur =
        databasesUserServices.getUserById(widget.transac.uidAcheteur);
    userVendeur = databasesUserServices.getUserById(widget.transac.uidVendeur);
  }

  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 0.5),
      child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: FutureBuilder<Post>(
            future: post,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                var postTransac = snapshot.data;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, left: 10),
                            child: MyTextStyle.lotName(
                                postTransac!.title, Colors.black87, 13),
                          ),
                        ),

                        Container(
                            padding: const EdgeInsets.only(top: 5, right: 10),
                            child:
                                MyTextStyle.lotDesc(widget.transac.statut, 13)),
                        // Divider(thickness: 3),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Divider(
                        thickness: 1,
                        color: Colors.black12,
                      ),
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35.0),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              width: 140,
                              height: 140,
                              child: postTransac.pathImage != ""
                                  ? Image.network(
                                      postTransac.pathImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : ImageAnnounced(context, 140, 140),
                            ),
                          ),
                        ),
                        Container(
                            padding: const EdgeInsets.only(top: 5, right: 10),
                            child: MyTextStyle.annonceDesc(
                                widget.transac.statut, 13, 3)),
                      ],
                    ),
                  ],
                );
              }
            },
          )),
    );
  }
}
