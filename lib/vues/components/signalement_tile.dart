import 'package:connect_kasa/controllers/features/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/signalement_count_controller.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/pages_vues/post_view.dart';
import 'package:flutter/material.dart';

class SignalementTile extends StatelessWidget {
  final Post post;
  final double width;
  final int postCount;
  final Function(int) postCountCallback;
  final String residence;
  final String uid;

  SignalementTile(this.post, this.width, this.postCount, this.postCountCallback,
      this.residence, this.uid);

  @override
  Widget build(BuildContext context) {
    final FormatProfilPic formatProfilPic = FormatProfilPic();
    final DataBasesServices _databaseServices = DataBasesServices();
    late Future<User?> userPost = _databaseServices.getUserById(post.user);
    postCountCallback(postCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: width / 1.5,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  post.pathImage ?? "pas d'image",
                  fit: BoxFit.cover,
                ),
              ),
              if (post.hideUser == true)
                Positioned(
                  top: 0,
                  left: 5,
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            top: 5, bottom: 5, left: 5, right: 5),
                        child: CircleAvatar(
                          radius: 20,
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
                                    return formatProfilPic.ProfilePic(
                                        17, userPost);
                                  } else {
                                    // Sinon, retourner les initiales
                                    return formatProfilPic.getInitiales(
                                        17, userPost, 17);
                                  }
                                } else {
                                  // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
                                  return formatProfilPic.getInitiales(
                                      16,
                                      userPost,
                                      3); // ou tout autre widget par défaut
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      FutureBuilder<User?>(
                        future: userPost,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else {
                            if (snapshot.hasData && snapshot.data != null) {
                              var user = snapshot.data!;
                              return MyTextStyle.lotName(
                                  "${user.pseudo}", Colors.white);
                            } else {
                              return Text('Utilisateur inconnue',
                                  style: TextStyle(
                                      color: Colors
                                          .white)); // Placeholder for unknown name
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MyTextStyle.lotName(post.title, Colors.black87),
                  Spacer(),
                  Container(
                    height: 20,
                    width: 120,
                    child: MyTextStyle.postDate(post.timeStamp),
                  ),
                ],
              ),
              Row(
                children: [
                  MyTextStyle.lotName("Localisation : ", Colors.black54),
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
              //SignalementsCountController(post: post, postCount: postCount),
            ],
          ),
        ),
      ],
    );
  }
}
