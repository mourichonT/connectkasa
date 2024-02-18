import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';

class CommentTile extends StatefulWidget {
  late Comment comment;
  late Future<User?> user;
  final String uid;

  CommentTile(this.comment, this.uid);

  @override
  State<StatefulWidget> createState() => CommentTileState();
}

class CommentTileState extends State<CommentTile> {
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesServices _databaseServices = DataBasesServices();
  late Comment comment;

  void initState() {
    super.initState();
    comment = widget.comment;
    widget.user = _databaseServices.getUserById(comment.user);
    // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Ajustez cette ligne
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 20),
            child: CircleAvatar(
                radius: 38,
                backgroundColor: Theme.of(context).primaryColor,
                child: FutureBuilder<User?>(
                  future: widget.user, // Future<User?> ici
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Afficher un indicateur de chargement si le futur est en cours de chargement
                      return CircularProgressIndicator();
                    } else {
                      // Si le futur est résolu, vous pouvez accéder aux propriétés de l'objet User
                      if (snapshot.hasData && snapshot.data != null) {
                        var user = snapshot.data!;
                        if (user.profilPic != null && user.profilPic != "") {
                          // Retourner le widget avec l'image de profil si disponible
                          return formatProfilPic.ProfilePic(35, widget.user);
                        } else {
                          // Sinon, retourner les initiales
                          return formatProfilPic.getInitiales(65, widget.user);
                        }
                      } else {
                        // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
                        return formatProfilPic.getInitiales(
                            65, widget.user); // ou tout autre widget par défaut
                      }
                    }
                  },
                )),
          ),
        ],
      ),
    );
  }
}
