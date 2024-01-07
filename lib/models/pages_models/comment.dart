import 'package:connect_kasa/models/pages_models/user.dart';

class Comment {


  String text;
  User user;
  DateTime date;
  int like;
  int dislike;


  Comment({
    required this.text,
    required this.user,
    required this.date,
    required this.like,
    required this.dislike});



  String setDate() => "$date";

  String setLike() {
    return "$like";
  }
  String setdisLike() {
    return "$dislike";
  }
}