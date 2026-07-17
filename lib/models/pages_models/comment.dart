import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  String comment;
  String user;
  Timestamp timestamp;
  List<String> like;
  String id;
  bool? originalCommment;
  String? initialComment;

  Comment({
    required this.comment,
    required this.user,
    required this.timestamp,
    required this.like,
    required this.id,
    this.originalCommment,
    this.initialComment,
  });

// Méthode toString() personnalisée pour afficher les détails du commentaire
  @override
  String toString() {
    return 'Comment{comment: $comment, user: $user, timestamp: $timestamp, like: $like, id: $id}, originalCommment : $originalCommment, initialComment:$initialComment';
  }

  String setLike(likeCount) {
    //  final likeCount = like.length;
    return "$likeCount";
  }

  String settimestamp() => "$timestamp";

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      comment: map['comment'] ?? '',
      user: map['user'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      like: List<String>.from(map['like'] ?? []),
      id: map['id'] ?? '',
      originalCommment: (map['originalCommment']),
      initialComment: map['initialComment'] ?? '',
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
      'originalCommment': originalCommment,
      'initialComment': initialComment
    };
  }
}
