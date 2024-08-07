import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String message;
  String userIdFrom;
  String userIdTo;
  Timestamp timestamp;

  Message({
    required this.message,
    required this.userIdFrom,
    required this.userIdTo,
    required this.timestamp,
  });

  factory Message.fromJsom(Map<String, dynamic> json) {
    return Message(
        message: json["message"],
        userIdFrom: json["userIdFrom"],
        userIdTo: json["userIdTo"],
        timestamp: json["timestamp"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "message": message,
      "userIdFrom": userIdFrom,
      "userIdTo": userIdTo,
      "timestamp": timestamp
    };
  }
}
