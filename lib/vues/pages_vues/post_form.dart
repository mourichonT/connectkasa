import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/pages_models/lot.dart';
import '../components/my_drop_down_residence.dart';

class PostForm extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => PostFormState();
}

class PostFormState extends State<PostForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyDropdownResidence(),
      ],
    );
  }
}
