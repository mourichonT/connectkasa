import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String title;
  String description;
  Timestamp date;
  List<String>? participants;

  Event({
    required this.title,
    required this.description,
    required this.date,
    this.participants,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'],
      description: json['description'],
      date: json['date'], // Assurez-vous que le formatage Timestamp est correct
      participants: List<String>.from(json['participants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date, // Assurez-vous que le formatage Timestamp est correct
      'participants': participants,
    };
  }
}
