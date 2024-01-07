import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/datas/datas_posts.dart';
import 'package:connect_kasa/vues/components/post_widget.dart';
import 'package:connect_kasa/vues/components/section_title.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/post.dart';

class Homeview extends StatelessWidget{

DatasPosts datasPosts = DatasPosts();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(

        child:
          ListView.separated(
            shrinkWrap: true,
              physics: BouncingScrollPhysics(),
            itemCount: datasPosts.posts().length,
            itemBuilder: (context, index) {
              return PostWidget(datasPosts.posts()[index]);
            }, separatorBuilder: (BuildContext context, int index)=> Container(
            padding: EdgeInsets.symmetric(vertical: 10)
          )),
      );
  }
}