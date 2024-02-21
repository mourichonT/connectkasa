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
  final Function(TextEditingController) getUsertoreply;
  late Comment comment;
  final String residence;
  final String postId;
  late Future<User?> user;
  final String uid;
  FocusNode focusNode;
  bool isReply = false;
  final TextEditingController textEditingController;

  CommentTile(this.residence, this.comment, this.uid, this.postId,
      this.focusNode, this.textEditingController,
      {this.isReply = false,
      required this.onReply,
      required this.getCommentData,
      required this.getUsertoreply});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentTile(comment),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: 25.0,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
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
                  getCommentData: widget.getCommentData,
                  getUsertoreply: widget.getUsertoreply,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCommentTile(Comment comment) {
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
                    EdgeInsets.only(top: 10, bottom: 5, left: 5, right: 15),
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
              Container(
                //padding: EdgeInsets.only(right: 15),
                child: Column(
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
                              return MyTextStyle.lotName(
                                  pseudo, Colors.black87);
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
                    Container(
                        width: MediaQuery.of(context).size.width * 0.55,
                        child: MyTextStyle.commentTextFormat(comment.comment)),
                    Row(
                      children: [
                        TextButton(
                          child:
                              MyTextStyle.lotName("Répondre", Colors.black54),
                          onPressed: () {
                            print("comment.id = ${comment.id}");
                            widget.isReply = true;
                            _replyToComment(comment, widget.isReply);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
      print("isREPLY = ${isReply}");
      widget.getCommentData(parentComment.id);

      String replyText = "@${user.surname}${user.name} ";
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
