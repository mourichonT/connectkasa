import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:flutter/material.dart';

class SignalementTile extends StatelessWidget {
  final Post post;
  final double width;
  final int postCount;
  final Function(int) postCountCallback;
  final String residence;
  final String uid;

  SignalementTile(this.post, this.width, this.postCount, this.postCountCallback,
      this.residence, this.uid,
      {super.key});

  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices databasesUserServices = DataBasesUserServices();
  late Future<User?> userPost = databasesUserServices.getUserById(post.user);
  @override
  Widget build(BuildContext context) {
    postCountCallback(postCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
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
              if (post.hideUser == false)
                Positioned(
                  top: 0,
                  left: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        ProfilTile(post.user, 22, 19, 22, true, Colors.white),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MyTextStyle.lotName(post.title, Colors.black87),
                    const Spacer(),
                    SizedBox(
                      height: 20,
                      width: 120,
                      child: MyTextStyle.postDate(post.timeStamp),
                    ),
                  ],
                ),
                post.location_element == ""
                    ? Container()
                    : Row(
                        children: [
                          MyTextStyle.lotName(
                              "Localisation : ", Colors.black54),
                          MyTextStyle.lotName(
                              "${post.location_element} ${post.location_floor} ",
                              Colors.black54),
                        ],
                      ),
                const SizedBox(
                  height: 15,
                ),
                Flexible(
                    child: MyTextStyle.annonceDesc(post.description, 14, 3)),
                const SizedBox(
                  height: 15,
                ),
                //SignalementsCountController(post: post, postCount: postCount),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



// FutureBuilder<User?>(
//                       future: userPost, // Future<User?> ici
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           // Afficher un indicateur de chargement si le futur est en cours de chargement
//                           return const CircularProgressIndicator();
//                         } else {
//                           // Si le futur est résolu, vous pouvez accéder aux propriétés de l'objet User
//                           if (snapshot.hasData && snapshot.data != null) {
//                             var user = snapshot.data!;
//                             if (user.profilPic != null &&
//                                 user.profilPic != "") {
//                               // Retourner le widget avec l'image de profil si disponible
//                               return Row(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 20,
//                                     backgroundColor:
//                                         Theme.of(context).primaryColor,
//                                     child: formatProfilPic.ProfilePic(
//                                         18, userPost),
//                                   ),
//                                   SizedBox(
//                                     width: 10,
//                                   ),
//                                   MyTextStyle.lotName(
//                                     user.pseudo!,
//                                     Colors.white,
//                                   ),
//                                 ],
//                               );
//                             } else {
//                               // Sinon, retourner les initiales
//                               return Row(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 20,
//                                     backgroundColor:
//                                         Theme.of(context).primaryColor,
//                                     child: formatProfilPic.getInitiales(
//                                         35, userPost, 20),
//                                   ),
//                                   SizedBox(
//                                     width: 10,
//                                   ),
//                                   MyTextStyle.lotName(
//                                     user.pseudo!,
//                                     Colors.white,
//                                   ),
//                                 ],
//                               );
//                             }
//                           } else {
//                             // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
//                             return Row(
//                               children: [
//                                 CircleAvatar(
//                                   radius: 20,
//                                   backgroundColor:
//                                       Theme.of(context).primaryColor,
//                                   child: formatProfilPic.getInitiales(
//                                       65, userPost, 3),
//                                 ),
//                                 SizedBox(
//                                   width: 5,
//                                 ),
//                                 MyTextStyle.lotName(
//                                   "Utilisteur inconnu",
//                                   Colors.white,
//                                 ),
//                               ],
//                             ); // ou tout autre widget par défaut
//                           }
//                         }
//                       },
//                     ),