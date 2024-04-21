import 'package:cloud_firestore/cloud_firestore.dart';

class Mail {
  List<String>? to;
  String? from;
  Timestamp startTime;
  String subject;
  String html;

  Mail({
    this.to,
    this.from,
    required this.startTime,
    required this.subject,
    required this.html,
  });

  // Méthode pour convertir un objet Mail en Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'to': to,
      'from': from,
      'startTime': startTime,
      'message': {
        'subject': subject,
        'html': html,
      },
    };
  }

  // Méthode pour créer un objet Mail à partir d'une Map (JSON)
  factory Mail.fromJson(Map<String, dynamic> json) {
    return Mail(
      to: json['to'] != null ? List<String>.from(json['to']) : null,
      from: json['delivery'] != null ? json['from'] : null,
      startTime: json['delivery']['startTime'],
      subject: json['message']['subject'],
      html: json['message']['html'],
    );
  }
}
