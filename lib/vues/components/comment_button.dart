import 'package:connect_kasa/vues/components/section_comment.dart';
import 'package:flutter/material.dart';
import '../../controllers/features/my_texts_styles.dart';
import '../../models/pages_models/post.dart';

class CommentButton extends StatefulWidget{
  final Post post;

  CommentButton({required this.post});

  @override
    State<StatefulWidget> createState()=> CommentButtonState();
}
class CommentButtonState extends State<CommentButton>{
  late Post post;

  @override
  void initState() {
    super.initState();
    post = widget.post; // Initialisez post à partir des propriétés du widget
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: Icon(
            (post!.comment>0)
            ?Icons.comment
            :Icons.messenger_outline_outlined, color:(post!.comment>0)? Theme.of(context).primaryColor:null, size: 20,),
          onPressed: (){
            showModalBottomSheet(
              context: context,
              //isScrollControlled: true,
              isDismissible: true,
              builder: (BuildContext){

                return SectionComment();
              }
            );
         },
        ),
        MyTextStyle.iconText(post.setComments())
      ],
    );
  }
}