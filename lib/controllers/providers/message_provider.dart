import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/chat_services.dart';
import 'package:connect_kasa/models/pages_models/message.dart';
import 'package:flutter/material.dart';

class MessageProvider extends ChangeNotifier {
  Message? _lastMessage;
  Stream<Message?>? _messageStream;
  bool _hasNewMessage = false;

  String? _userFrom;
  String? _residenceId;

  final StreamController<bool> _hasNewMessageController =
      StreamController<bool>.broadcast();

  Stream<bool> get hasNewMessageStream => _hasNewMessageController.stream;

  Message? get lastMessage => _lastMessage;
  bool get hasNewMessage => _hasNewMessage;

  StreamSubscription<QuerySnapshot>? _chatSubscription;

  MessageProvider() {
    print('[MessageProvider] Initialisé');
  }

  /// Initialise la détection du dernier message (existant)
  void init({
    required String residenceId,
    required String userFrom,
    required String userTo,
  }) {
    _userFrom = userFrom;
    print(
        '[MessageProvider.init] residenceId=$residenceId, userFrom=$userFrom, userTo=$userTo');

    _messageStream = ChatServices.getLastMessageBetweenUsers(
      residenceId: residenceId,
      userA: userFrom,
      userB: userTo,
    );

    _messageStream!.listen((message) {
      print('[MessageProvider.init] Nouveau message reçu : $message');

      final bool isFromOtherUser =
          message != null && message.userIdFrom != _userFrom;
      final bool isNew =
          message != null && message.timestamp != _lastMessage?.timestamp;

      final bool shouldNotify = isFromOtherUser && isNew;

      print(
          '[MessageProvider.init] isFromOtherUser=$isFromOtherUser, isNew=$isNew, shouldNotify=$shouldNotify');

      _lastMessage = message;
      _hasNewMessage = shouldNotify;
      _hasNewMessageController.add(shouldNotify);

      notifyListeners();
    });
  }

  /// Écoute les chats Firestore pour détecter les messages non lus (avec from_msg_num / to_msg_num)
  void listenForMessages({
    required String residenceId,
    required String currentUserId,
  }) {
    _residenceId = residenceId;
    _userFrom = currentUserId;

    print(
        '[MessageProvider.listenForMessages] residenceId=$residenceId, currentUserId=$currentUserId');

    // Annule l'ancienne subscription si elle existe
    _chatSubscription?.cancel();

    _chatSubscription = FirebaseFirestore.instance
        .collection("Residence")
        .doc(residenceId)
        .collection("chat")
        .snapshots()
        .listen((chatSnapshot) {
      print(
          '[MessageProvider.listenForMessages] Snapshot reçu avec ${chatSnapshot.docs.length} docs');

      bool foundNewMessage = false;

      for (var chatDoc in chatSnapshot.docs) {
        final chatData = chatDoc.data();
        final fromId = chatData["from_id"];
        final toId = chatData["to_id"];
        final fromMsgNum = chatData["from_msg_num"] ?? 0;
        final toMsgNum = chatData["to_msg_num"] ?? 0;

        print(
            ' - chatDoc fromId=$fromId, toId=$toId, fromMsgNum=$fromMsgNum, toMsgNum=$toMsgNum');

        if (currentUserId == fromId && toMsgNum > 0) {
          foundNewMessage = false;
          print(' → Nouveau message détecté pour TESTET currentUserId $fromId');
          break;
        } else if (currentUserId == toId && toMsgNum > 0) {
          foundNewMessage = true;
          print(
              ' → je test la condition currentUserId == toId && toMsgNum > 0');
          break;
        } else if (currentUserId == toId && fromMsgNum > 0) {
          foundNewMessage = false;
          print(
              ' → je test la condition currentUserId == toId && fromMsgNum > 0');
          break;
        } else if (currentUserId == fromId && fromMsgNum > 0) {
          foundNewMessage = true;
          print(
              ' → je test la condition currentUserId == fromId && fromMsgNum > 0');
          break;
        }
      }

      _hasNewMessage = foundNewMessage;
      _hasNewMessageController.add(foundNewMessage);
      notifyListeners();

      print(
          '[MessageProvider.listenForMessages] hasNewMessage = $foundNewMessage');
    });
  }

  /// Pour reset le flag (ex: quand on ouvre la page messages)
  void clearNewMessageFlag() {
    print('[MessageProvider.clearNewMessageFlag] Reset du flag');
    _hasNewMessage = false;
    _hasNewMessageController.add(false);
    notifyListeners();
  }

  @override
  void dispose() {
    print('[MessageProvider.dispose] Dispose appelé');
    _chatSubscription?.cancel();
    _hasNewMessageController.close();
    super.dispose();
  }
}
