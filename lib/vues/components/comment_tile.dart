import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/like_button_comment.dart';
import 'package:connect_kasa/vues/components/like_button_post.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';

class CommentTile extends StatefulWidget {
  late Comment comment;
  final String residence;
  final String postId;
  late Future<User?> user;
  final String uid;
  FocusNode focusNode;
  bool isReply = false;

  CommentTile(
      this.residence, this.comment, this.uid, this.postId, this.focusNode,
      {isReply = false});

  @override
  State<StatefulWidget> createState() => CommentTileState();
}

class CommentTileState extends State<CommentTile> {
  TextEditingController _textEditingController = TextEditingController();
  late Future<User?> user;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesServices _databaseServices = DataBasesServices();
  late Comment comment;

  void initState() {
    super.initState();
    comment = widget.comment;
    user = _databaseServices.getUserById(comment.user);
    // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ajustez cette ligne
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Ajustez cette ligne
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Padding(
                padding:
                    EdgeInsets.only(top: 10, bottom: 5, left: 5, right: 20),
                child: CircleAvatar(
                    radius: 23,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: FutureBuilder<User?>(
                      future: user, // Future<User?> ici
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
                                  27, Future.value(user));
                            } else {
                              // Sinon, retourner les initiales
                              return formatProfilPic.getInitiales(33, user);
                            }
                          } else {
                            // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
                            return formatProfilPic.getInitiales(
                                65, user); // ou tout autre widget par défaut
                          }
                        }
                      },
                    )),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    FutureBuilder<User?>(
                      future: user,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Affiche un widget de chargement pendant que les données sont chargées
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          // Affiche un message d'erreur si une erreur se produit lors du chargement des données
                          return Text("Error: ${snapshot.error}");
                        } else if (snapshot.hasData && snapshot.data != null) {
                          // Affiche le nom de l'utilisateur si les données sont disponibles
                          var user = snapshot.data!;
                          String pseudo = user.surname + ' ' + user.name;
                          return MyTextStyle.lotName(pseudo, Colors.black87);
                        } else {
                          // Si les données sont null, affiche un widget vide ou un message d'absence de données
                          return SizedBox();
                        }
                      },
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Container(
                      child: MyTextStyle.commentDate(comment.timestamp),
                    )
                  ]),
                  MyTextStyle.lotDesc(comment.comment),
                  Row(children: [
                    TextButton(
                      child: MyTextStyle.lotName("Répondre", Colors.black54),
                      onPressed: () {
                        // Ouvrir le TextEditingController pour répondre au commentaire
                        _replyToComment(comment);
                      },
                    ),
                  ]),
                ],
              ),
            ])),
        Container(
            child: LikeButtonComment(
          residence: widget.residence,
          uid: widget.uid,
          comment: comment,
          postId: widget.postId,
        )),
      ],
    );
  }

  void _replyToComment(Comment parentComment) {
    widget.isReply = true;

    // Focus sur le commentaire en réponse
    FocusScope.of(context).requestFocus(widget.focusNode);

    // Récupérer le texte existant du commentaire
    String existingText = _textEditingController.text;

    // Ajouter une mention du commentaire parent
    String replyText = "@${parentComment.user} ";

    // Ajouter le texte existant (s'il existe)
    if (existingText.isNotEmpty) {
      replyText += existingText + ' ';
    }

    // Mettre à jour le texte dans le TextEditingController
    _textEditingController.text = replyText;
    _textEditingController;

    // Placer le curseur à la fin du texte
    _textEditingController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textEditingController.text.length),
    );
  }
}
