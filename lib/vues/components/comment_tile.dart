import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/like_button_comment.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';

class CommentTile extends StatefulWidget {
  final Function(bool) onReply;
  final Function(String) getCommentData;
  late Comment comment;
  final String residence;
  final String postId;
  late Future<User?> user;
  final String uid;
  FocusNode focusNode;
  bool isReply = false;

  CommentTile(
      this.residence, this.comment, this.uid, this.postId, this.focusNode,
      {this.isReply = false,
      required this.onReply,
      required this.getCommentData});

  @override
  State<StatefulWidget> createState() => CommentTileState();
}

class CommentTileState extends State<CommentTile> {
  TextEditingController _textEditingController = TextEditingController();
  late Future<User?> user;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesServices _databaseServices = DataBasesServices();
  late Comment comment;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    comment = widget.comment;
    user = _databaseServices.getUserById(comment.user);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
                    future: user,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else {
                        if (snapshot.hasData && snapshot.data != null) {
                          var user = snapshot.data!;
                          if (user.profilPic != null && user.profilPic != "") {
                            return formatProfilPic.ProfilePic(
                                27, Future.value(user));
                          } else {
                            return formatProfilPic.getInitiales(33, user);
                          }
                        } else {
                          return formatProfilPic.getInitiales(65, user);
                        }
                      }
                    },
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FutureBuilder<User?>(
                        future: user,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}");
                          } else if (snapshot.hasData &&
                              snapshot.data != null) {
                            var user = snapshot.data!;
                            String pseudo = user.surname + ' ' + user.name;
                            return MyTextStyle.lotName(pseudo, Colors.black87);
                          } else {
                            return SizedBox();
                          }
                        },
                      ),
                      SizedBox(width: 10),
                      Container(
                        child: MyTextStyle.commentDate(comment.timestamp),
                      ),
                    ],
                  ),
                  MyTextStyle.lotDesc(comment.comment),
                  Row(
                    children: [
                      TextButton(
                        child: MyTextStyle.lotName("Répondre", Colors.black54),
                        onPressed: () {
                          widget.isReply = true;
                          _replyToComment(comment, widget.isReply);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          child: LikeButtonComment(
            residence: widget.residence,
            uid: widget.uid,
            comment: comment,
            postId: widget.postId,
          ),
        ),
      ],
    );
  }

  void _replyToComment(Comment parentComment, bool isReply) async {
    User? user = await _databaseServices.getUserById(parentComment.user);
    if (user != null) {
      FocusScope.of(context).requestFocus(widget.focusNode);
      widget.onReply(isReply);
      widget.getCommentData(parentComment.id);

      String replyText = "@${user.surname}${user.name} ";
      _textEditingController.text = replyText;
      _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textEditingController.text.length),
      );
    } else {
      print("Utilisateur non trouvé");
    }
  }
}
