import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';

import '../../vues/pages_vues/post_form.dart';

class PostFormController extends StatelessWidget{

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName('Déclarer un nouveau sinistre/incivilité'),
      ),
      body : PostForm(),

    );
  }

}