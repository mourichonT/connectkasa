import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/vues/components/comment_tile.dart';
import 'package:flutter/material.dart';

class SectionComment extends StatefulWidget {
  String residenceSelected;
  String postSelected;
  String uid;

  SectionComment(
      {Key? key,
      required this.residenceSelected,
      required this.postSelected,
      required this.uid})
      : super(key: key);

  @override
  _SectionCommentState createState() => _SectionCommentState();
}

class _SectionCommentState extends State<SectionComment> {
  TextEditingController _textEditingController = TextEditingController();
  final DataBasesServices _databaseServices = DataBasesServices();
  late Future<List<Comment>> _allComments;

  @override
  void initState() {
    super.initState();
    _allComments = _databaseServices.getComments(
        widget.residenceSelected, widget.postSelected);
  }

  @override
  Widget build(BuildContext context) {
    print('je verifie la residence : ${widget.residenceSelected}');
    print('je verifie le post ${widget.postSelected}');
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
          return SingleChildScrollView(
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemCount: _allComments.length,
                  itemBuilder: (context, index) {
                    Comment comment = _allComments[index];
                    return Column(
                      children: [CommentTile(comment, widget.uid)],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                _buildCommentInput(), // Ajout du champ de commentaire en bas
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (_textEditingController.text.isNotEmpty) {
                //_addComment(_textEditingController.text);
                _textEditingController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  // void _addComment(String comment) {
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
