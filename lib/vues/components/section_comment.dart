import 'package:flutter/material.dart';

class SectionComment extends StatefulWidget {
  @override
  _SectionCommentState createState() => _SectionCommentState();
}

class _SectionCommentState extends State<SectionComment> {
  List<String> comments = ["Commentaire 1", "Commentaire 2", "Commentaire 3", "Commentaire 4", "Commentaire 5", "Commentaire 6"];
  TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(comments[index]),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.grey),
          _buildCommentInput(),
        ],
      ),
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
                onSubmitted: (comment) {
                  _addComment(comment);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              (_textEditingController.text.isNotEmpty)?_addComment(_textEditingController.text):null;
              _textEditingController.clear();
              _textEditingController.dispose();
              _textEditingController = TextEditingController(); // Crée un nouveau contrôleur
            },
          ),
        ],
      ),
    );
  }

  void _addComment(String comment) {
    setState(() {
      comments.add(comment);
    });
  }
}
