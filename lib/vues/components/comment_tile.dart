// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/like_button_comment.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';

class CommentTile extends StatefulWidget {
  final Function(bool) onReply;
  final Function(String) getCommentId;
  final Function(TextEditingController) getUsertoreply;
  late Comment comment;
  final String residence;
  final String postId;
  late Future<User?> user;
  final String uid;
  FocusNode focusNode;
  bool isReply = false;
  final TextEditingController textEditingController;
  final Function(String?) getInitialComment;

  CommentTile(
    this.residence,
    this.comment,
    this.uid,
    this.postId,
    this.focusNode,
    this.textEditingController, {
    super.key,
    this.isReply = false,
    required this.onReply,
    required this.getCommentId,
    required this.getUsertoreply,
    required this.getInitialComment,
  });

  @override
  State<StatefulWidget> createState() => CommentTileState();
}

class CommentTileState extends State<CommentTile> {
  TextEditingController _textEditingController = TextEditingController();
  late Future<User?> user;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices _databasesUserServices = DataBasesUserServices();
  late Comment comment;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    comment = widget.comment;
    user = _databasesUserServices.getUserById(comment.user);
  }

  @override
  Widget build(BuildContext context) {
    //Color colorStatut = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentTile(comment),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: 25.0,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comment.replies.length,
              itemBuilder: (context, index) {
                return CommentTile(
                  widget.residence,
                  comment.replies[index],
                  widget.uid,
                  widget.postId,
                  widget.focusNode,
                  widget.textEditingController,
                  onReply: widget.onReply,
                  getCommentId: widget.getCommentId,
                  getUsertoreply: widget.getUsertoreply,
                  getInitialComment: widget.getInitialComment,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCommentTile(Comment comment) {
    Color colorStatut = Theme.of(context).primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 10, bottom: 5, left: 5, right: 15),
              child: CircleAvatar(
                radius: 23,
                backgroundColor: Theme.of(context).primaryColor,
                child: FutureBuilder<User?>(
                  future: user,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else {
                      if (snapshot.hasData && snapshot.data != null) {
                        var user = snapshot.data!;
                        if (user.profilPic != null && user.profilPic != "") {
                          return formatProfilPic.ProfilePic(
                              27, Future.value(user));
                        } else {
                          return formatProfilPic.getInitiales(
                              40, Future.value(user), 25);
                        }
                      } else {
                        return formatProfilPic.getInitiales(
                            37, Future.value(user), 25);
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
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        } else if (snapshot.hasData && snapshot.data != null) {
                          var user = snapshot.data!;
                          String pseudo = user.pseudo;
                          return MyTextStyle.lotName(pseudo, Colors.black87);
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    Container(
                      child: MyTextStyle.commentDate(comment.timestamp),
                    ),
                  ],
                ),
                SizedBox(
                    width: MediaQuery.of(context).size.width * 0.50,
                    child: MyTextStyle.commentTextFormat(comment.comment)),
                Row(
                  children: [
                    TextButton(
                      child: MyTextStyle.lotName("Répondre", Colors.black54),
                      onPressed: () {
                        String initComment = "";

                        if (widget.comment.originalCommment == false) {
                          initComment = comment.initialComment!;
                          widget.isReply = true;
                          _replyToComment(comment, widget.isReply, initComment);
                        } else {
                          widget.isReply = true;
                          initComment = widget.comment.id;
                          _replyToComment(comment, widget.isReply,
                              initComment); // initComment
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        LikeButtonComment(
          residence: widget.residence,
          uid: widget.uid,
          comment: comment,
          postId: widget.postId,
          color: colorStatut,
        ),
      ],
    );
  }

  void _replyToComment(
      Comment currentComment, bool isReply, String? initComment) async {
    User? user = await _databasesUserServices.getUserById(currentComment.user);
    if (user != null) {
      FocusScope.of(context).requestFocus(widget.focusNode);
      widget.getUsertoreply(_textEditingController);
      widget.onReply(isReply);
      widget.getCommentId(currentComment.id);
      widget.getInitialComment(initComment);

      String replyText = "@${user.pseudo} ";
      _textEditingController.text = replyText;

      _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textEditingController.text.length),
      );
      widget.getUsertoreply(_textEditingController);
    } else {
      print("Utilisateur non trouvé");
    }
  }
}
