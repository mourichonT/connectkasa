import 'package:connect_kasa/controllers/services/chat_services.dart';
import 'package:connect_kasa/models/pages_models/message.dart';
import 'package:flutter/material.dart';

class MessageProvider extends ChangeNotifier {
  Message? _lastMessage;
  Stream<Message?>? _messageStream;

  Message? get lastMessage => _lastMessage;
  Stream<Message?>? get stream => _messageStream;

  MessageProvider() {
    // Exemple : initialiser un stream "générique" (peut être null ou vide)
    _messageStream = null;
  }

  // Tu peux ajouter une méthode pour initialiser plus tard avec les paramètres
  void init({
    required String residenceId,
    required String userFrom,
    required String userTo,
  }) {
    _messageStream = ChatServices.getLastMessageBetweenUsers(
      residenceId: residenceId,
      userA: userFrom,
      userB: userTo,
    );
    _messageStream!.listen((message) {
      _lastMessage = message;
      notifyListeners();
    });
  }
}
