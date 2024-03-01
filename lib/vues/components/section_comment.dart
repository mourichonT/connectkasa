import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/comment_tile.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SectionComment extends StatefulWidget {
  String residenceSelected;
  String postSelected;
  String uid;
  Future<List<Comment>> comment;
  final void Function() onCommentAdded;

  SectionComment({
    Key? key,
    required this.comment,
    required this.residenceSelected,
    required this.postSelected,
    required this.uid,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  _SectionCommentState createState() => _SectionCommentState();
}

class _SectionCommentState extends State<SectionComment>
    with WidgetsBindingObserver {
  double keyBoardHeight = 0;
  FocusNode inputFocusNode = FocusNode();
  bool focused = false;
  TextEditingController _textEditingController = TextEditingController();
  final DataBasesServices _databaseServices = DataBasesServices();
  late Future<List<Comment>> _allComments;
  bool isReply = false;
  String commentId = "";
  String initialComment = "";
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _allComments = widget.comment;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final mediaQuery = MediaQuery.of(context);
    setState(() {
      keyBoardHeight = mediaQuery.viewInsets.bottom != 0.0
          ? mediaQuery.viewInsets.bottom - 20.0
          : 0.0;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Comment>>(
      future: _allComments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<Comment> _allComments = snapshot.data!;
          return Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemCount: _allComments.length,
                  itemBuilder: (context, index) {
                    Comment comment = _allComments[index];
                    return Column(
                      children: [
                        CommentTile(
                            widget.residenceSelected,
                            comment,
                            widget.uid,
                            widget.postSelected,
                            inputFocusNode,
                            _textEditingController, onReply: (value) {
                          setState(() {
                            isReply =
                                value; // Mettre à jour isReply lorsque la valeur change
                          });
                        }, getCommentId: (value) {
                          setState(() {
                            commentId =
                                value; // Mettre à jour commentId lorsque la valeur change
                          });
                        }, getUsertoreply: (value) {
                          setState(() {
                            _textEditingController = value;
                          });
                        }, getInitialComment: (value) {
                          setState(() {
                            initialComment = value!;
                          });
                        })
                      ],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(
                    thickness: 0.5,
                  ),
                ),
                // Ajout du champ de commentaire en bas
              ),
              _buildCommentInput(context),
            ],
          );
        }
      },
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Positioned(
      bottom: keyBoardHeight,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(inputFocusNode);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.all(Radius.circular(30.0))),
              padding: EdgeInsets.symmetric(vertical: 3, horizontal: 30),
              width: MediaQuery.of(context).size.width * 0.8,
              child: IgnorePointer(
                child: TextField(
                  controller: _textEditingController,
                  focusNode: inputFocusNode,
                  decoration: const InputDecoration(
                    hintMaxLines: 20,
                    hintText: 'Ajouter un commentaire...',
                  ),
                ),
              ),
            ),
            Container(
              child: IconButton(
                color: Theme.of(context).colorScheme.primary,
                icon: Icon(Icons.send_rounded),
                onPressed: () {
                  if (isReply == true) {
                    if (_textEditingController.text.isNotEmpty) {
                      _addComment(
                        _textEditingController,
                        isReply,
                        commentId: commentId,
                        initialComment: initialComment,
                      );
                      _textEditingController.clear();
                    }
                  } else {
                    if (isReply == false &&
                        _textEditingController.text.isNotEmpty) {
                      _addComment(
                        _textEditingController,
                        isReply,
                        commentId: commentId,
                        initialComment: initialComment,
                      );
                      _textEditingController.clear();
                    }
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _addComment(TextEditingController textEditingController, bool isReply,
      {String? commentId,
      required String? initialComment,
      bool? originalCommment}) async {
    String commentFormatted = "";
    var uuid = Uuid();
    String uniqueId = uuid.v4();
    if (isReply == true) {
      final String formattedComment =
          _formatComment(textEditingController.text);

      await _databaseServices.addComment(
          widget.residenceSelected,
          widget.postSelected,
          Comment(
            comment: formattedComment,
            user: widget.uid,
            timestamp: Timestamp.now(),
            like: [],
            id: uniqueId,
            originalCommment: !isReply,
            initialComment: initialComment,
          ),
          commentId: commentId,
          initialComment: initialComment);

      setState(() {
        _allComments = _databaseServices.getComments(
            widget.residenceSelected, widget.postSelected);
      });
      // isReply = false;
    } else {
      try {
        // Ajouter le commentaire à la base de données
        await _databaseServices.addComment(
          widget.residenceSelected,
          widget.postSelected,
          Comment(
            comment: _textEditingController.text,
            user: widget.uid,
            timestamp: Timestamp.now(),
            like: [],
            id: uniqueId,
            originalCommment: !isReply,
          ),
        );
        // Actualiser la liste des commentaires
        setState(() {
          _allComments = _databaseServices.getComments(
              widget.residenceSelected, widget.postSelected);
        });
      } catch (e) {
        print("Error adding comment: $e");
        // Gérer l'erreur
      }
    }
    widget.onCommentAdded();
  }

  String _formatComment(String comment) {
    final RegExp regex = RegExp(r"@([A-Z][a-z]+(?:[A-Z][a-z]+)*)\s+(.*)");
    final Iterable<Match> matches = regex.allMatches(comment);
    String formattedComment = "";

    for (final Match match in matches) {
      final String name = match.group(1)!;
      final String restOfThePhrase = match.group(2)!;
      final String formattedName =
          name.replaceAllMapped(RegExp(r"(?=[A-Z])"), (match) => " ");

      formattedComment += "$formattedName $restOfThePhrase";
    }

    return formattedComment.isNotEmpty ? formattedComment : comment;
  }
}
