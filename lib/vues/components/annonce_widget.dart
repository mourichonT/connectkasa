import 'package:connect_kasa/controllers/features/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';
import '../../models/pages_models/post.dart';

class AnnonceWidget extends StatefulWidget {
  late Post post;
  late Future<User?> userPost;

  AnnonceWidget(this.post);
  @override
  State<StatefulWidget> createState() => AnnonceWidgetState();
}

class AnnonceWidgetState extends State<AnnonceWidget> {
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesServices _databaseServices = DataBasesServices();
  late Future<User?> userPost;
  late Post post;
  void initState() {
    super.initState();
    post = widget.post;
    userPost = _databaseServices.getUserById(post.user);
    // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    _databaseServices.getUserById(post.user);
    return InkWell(
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 8, offset: Offset(0, 1))
        ]),
        child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Ajustez cette ligne
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 20),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: FutureBuilder<User?>(
                        future: userPost, // Future<User?> ici
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // Afficher un indicateur de chargement si le futur est en cours de chargement
                            return CircularProgressIndicator();
                          } else {
                            // Si le futur est résolu, vous pouvez accéder aux propriétés de l'objet User
                            if (snapshot.hasData && snapshot.data != null) {
                              var user = snapshot.data!;
                              if (user.profilPic != null &&
                                  user.profilPic != "") {
                                // Retourner le widget avec l'image de profil si disponible
                                return formatProfilPic.ProfilePic(35, userPost);
                              } else {
                                // Sinon, retourner les initiales
                                return formatProfilPic.getInitiales(
                                    65, userPost);
                              }
                            } else {
                              // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
                              return formatProfilPic.getInitiales(65,
                                  userPost); // ou tout autre widget par défaut
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: MyTextStyle.lotName(post.title),
                            ),
                            Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Row(children: [
                                  Container(
                                      height: 20,
                                      width: 120,
                                      child: MyTextStyle.lotDesc(
                                          post.subtype ?? 'n/a')),
                                  Spacer(),
                                  Container(
                                      height: 20,
                                      width: 120,
                                      child:
                                          MyTextStyle.postDate(post!.timeStamp))
                                ])),
                            Flexible(
                              child: MyTextStyle.annonceDesc(post.description),
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
