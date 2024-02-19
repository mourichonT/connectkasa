import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/vues/components/comment_tile.dart';
import 'package:flutter/material.dart';

class SectionComment extends StatefulWidget {
  String residenceSelected;
  String postSelected;
  String uid;
  Future<List<Comment>> comment;

  SectionComment(
      {Key? key,
      required this.comment,
      required this.residenceSelected,
      required this.postSelected,
      required this.uid})
      : super(key: key);

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
      print("keyBoardHeight = $keyBoardHeight");
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
                          isReply: isReply,
                        )
                      ],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      Divider(
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
        child: Container(
          decoration:
              BoxDecoration(color: Theme.of(context).colorScheme.background),
          padding: EdgeInsets.all(8.0),
          width: MediaQuery.of(context).size.width,
          child: IgnorePointer(
            child: TextField(
              controller: _textEditingController,
              focusNode: inputFocusNode,
              decoration: const InputDecoration(
                hintText: 'Ajouter un commentaire...',
              ),
            ),
          ),
          // IconButton(
          //   icon: Icon(Icons.send),
          //   onPressed: () {
          //     if (_textEditingController.text.isNotEmpty) {
          //       //_addComment(_textEditingController.text, isReply);
          //       _textEditingController.clear();
          //     }
          //   },
          // ),
        ),
      ),
    );
  }

  // void _addComment(String comment, bool isReply) {
// if (isReply)....databaseservice.reply faire un isReply=false

  //   // Vous devrez ajouter la logique pour ajouter le commentaire à la base de données
  //   // ou à votre liste locale de commentaires
  //   // Par exemple :
  //   setState(() {
  //     _allComments.add(Comment(
  //       text: comment,
  //       user: widget.uid,
  //       date: DateTime.now(),
  //       like: [], // Vous pouvez initialiser la liste de likes comme vous le souhaitez
  //     ));
  //   });
  // }
}
