import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String message;
  String userId;
  Timestamp timestamp;

  Message({
    required this.message,
    required this.userId,
    required this.timestamp,
  });

  factory Message.fromJsom(Map<String, dynamic> json) {
    return Message(
        message: json["name"],
        userId: json["userId"],
        timestamp: json["timestamp"]);
  }
}
