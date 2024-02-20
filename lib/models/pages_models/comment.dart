import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  String comment;
  String user;
  Timestamp timestamp;
  List<String> like;
  String id;

  Comment(
      {required this.comment,
      required this.user,
      required this.timestamp,
      required this.like,
      required this.id});

  String setLike(likeCount) {
    //  final likeCount = like.length;
    return "$likeCount";
  }

  String settimestamp() => "$timestamp";

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      comment: map['comment'] ?? '',
      user: map['user'] ?? '',
      // La timestamp doit être convertie en objet Timestamp
      timestamp: map['timestamp'] ?? "",
      // La liste des likes doit être convertie depuis une liste de dynamic en une liste de String
      like: List<String>.from(map['like'] ?? []),
      id: map['id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    // Génère un UUID v4 unique
    return {
      'comment': comment,
      'user': user,
      'timestamp': timestamp,
      'like': like,
      'id': id,
    };
  }
}
