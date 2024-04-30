// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';
import '../../models/pages_models/post.dart';

class AnnonceWidget extends StatefulWidget {
  late Post post;
  late Future<User?> userPost;

  AnnonceWidget(this.post, {super.key});
  @override
  State<StatefulWidget> createState() => AnnonceWidgetState();
}

class AnnonceWidgetState extends State<AnnonceWidget> {
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices _databasesUserServices = DataBasesUserServices();
  late Post post;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    widget.userPost = _databasesUserServices.getUserById(post.user);
    // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    _databasesUserServices.getUserById(post.user);
    return InkWell(
      child: Container(
        decoration: const BoxDecoration(boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 10, offset: Offset(0, 3))
        ]),
        child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Ajustez cette ligne
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 5, bottom: 5, left: 5, right: 20),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: FutureBuilder<User?>(
                        future: widget.userPost, // Future<User?> ici
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // Afficher un indicateur de chargement si le futur est en cours de chargement
                            return const CircularProgressIndicator();
                          } else {
                            // Si le futur est résolu, vous pouvez accéder aux propriétés de l'objet User
                            if (snapshot.hasData && snapshot.data != null) {
                              var user = snapshot.data!;
                              if (user.profilPic != null &&
                                  user.profilPic != "") {
                                // Retourner le widget avec l'image de profil si disponible
                                return formatProfilPic.ProfilePic(
                                    35, widget.userPost);
                              } else {
                                // Sinon, retourner les initiales
                                return formatProfilPic.getInitiales(
                                    65, widget.userPost, 37);
                              }
                            } else {
                              // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
                              return formatProfilPic.getInitiales(
                                  65,
                                  widget.userPost,
                                  3); // ou tout autre widget par défaut
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: MyTextStyle.lotName(
                                  post.title, Colors.black87),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(children: [
                                  SizedBox(
                                      height: 20,
                                      width: 120,
                                      child: MyTextStyle.lotDesc(
                                          post.subtype ?? 'n/a', 13)),
                                  const Spacer(),
                                  SizedBox(
                                      height: 20,
                                      width: 120,
                                      child:
                                          MyTextStyle.postDate(post.timeStamp))
                                ])),
                            Flexible(
                              child: MyTextStyle.annonceDesc(
                                  post.description, 14, 3),
                            ),
                          ],
                        )),
                  )
                ],
              ),
            )),
      ),
      onTap: () {
        //Navigator.push(context, route);
      },
    );
  }
}
