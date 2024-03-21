// ignore_for_file: file_names
// import 'package:flutter/material.dart';
// import 'package:connect_kasa/models/pages_models/post.dart';
// import 'package:connect_kasa/controllers/services/databases_services.dart';
// import 'package:connect_kasa/vues/components/like_button_post.dart';

// class LikeButtonController extends StatefulWidget {
//   final Post post;
//   final String residence;
//   final String uid;
//   final Color colorIcon;
//   final Color? colorText;

//   LikeButtonController({
//     required this.post,
//     required this.residence,
//     required this.uid,
//     required this.colorIcon,
//     this.colorText,
//   });

//   @override
//   _LikeButtonControllerState createState() => _LikeButtonControllerState();
// }

// class _LikeButtonControllerState extends State<LikeButtonController> {
//   int likeCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     likeCount = widget.post.like.length;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LikeButtonPost(
//       post: widget.post,
//       residence: widget.residence,
//       uid: widget.uid,
//       colorIcon: widget.colorIcon,
//       colorText: widget.colorText,
//     );
//   }
// }
