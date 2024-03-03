import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/material.dart';

class PostsController extends StatefulWidget {
  int postCount;
  late Post post;

  PostsController({required this.post, required this.postCount});

  @override
  _PostsControllerState createState() => _PostsControllerState();
}

class _PostsControllerState extends State<PostsController> {
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _postCount = widget.postCount;
  }

  @override
  Widget build(BuildContext context) {
    Color colorStatut = Theme.of(context).primaryColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Spacer(),
          (_postCount > 1)
              ? Icon(Icons.notifications,
                  color: Theme.of(context).primaryColor, size: 20)
              : Icon(Icons.notifications_none, size: 20),
          MyTextStyle.iconText(widget.post.setSignalement(_postCount)),
        ],
      ),
    );
  }
}
