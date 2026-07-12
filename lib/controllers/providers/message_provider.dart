import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/repositories/firestore_chat_repository.dart';
import 'package:konodal/models/pages_models/message.dart';
import 'package:flutter/material.dart';
import 'package:konodal/core/utils/app_logger.dart';

class MessageProvider extends ChangeNotifier {
  final FirestoreChatRepository _chatRepository = FirestoreChatRepository();

  Message? _lastMessage;
  StreamSubscription<dynamic>? _messageSubscription;
  bool _hasNewMessage = false;

  String? _userFrom;

  final StreamController<bool> _hasNewMessageController =
      StreamController<bool>.broadcast();

  Stream<bool> get hasNewMessageStream => _hasNewMessageController.stream;

  Message? get lastMessage => _lastMessage;
  bool get hasNewMessage => _hasNewMessage;

  StreamSubscription<QuerySnapshot>? _chatSubscription;

  MessageProvider() {
    appLog('[MessageProvider] Initialisé');
  }

  /// Initialise la détection du dernier message (existant)
  void init({
    required String residenceId,
    required String userFrom,
    required String userTo,
  }) {
    _userFrom = userFrom;
    appLog(
        '[MessageProvider.init] residenceId=$residenceId, userFrom=$userFrom, userTo=$userTo');

    _messageSubscription?.cancel();
    _messageSubscription = _chatRepository
        .getLastMessageBetweenUsers(
      residenceId: residenceId,
      userA: userFrom,
      userB: userTo,
    )
        .listen((result) {
      final message = result.when(success: (m) => m, failure: (_) => null);
      appLog('[MessageProvider.init] Nouveau message reçu : $message');

      final bool isFromOtherUser =
          message != null && message.userIdFrom != _userFrom;
      final bool isNew =
          message != null && message.timestamp != _lastMessage?.timestamp;

      final bool shouldNotify = isFromOtherUser && isNew;

      appLog(
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
    _userFrom = currentUserId;

    appLog(
        '[MessageProvider.listenForMessages] residenceId=$residenceId, currentUserId=$currentUserId');

    // Annule l'ancienne subscription si elle existe
    _chatSubscription?.cancel();

    _chatSubscription = FirebaseFirestore.instance
        .collection("residences")
        .doc(residenceId)
        .collection("chats")
        .where(Filter.or(
          Filter('from_id', isEqualTo: currentUserId),
          Filter('to_id', isEqualTo: currentUserId),
        ))
        .snapshots()
        .listen((chatSnapshot) {
      appLog(
          '[MessageProvider.listenForMessages] Snapshot reçu avec ${chatSnapshot.docs.length} docs');

      bool foundNewMessage = false;

      for (var chatDoc in chatSnapshot.docs) {
        final chatData = chatDoc.data();
        final fromId = chatData["from_id"];
        final toId = chatData["to_id"];
        final fromMsgNum = chatData["from_msg_num"] ?? 0;
        final toMsgNum = chatData["to_msg_num"] ?? 0;

        appLog(
            ' - chatDoc fromId=$fromId, toId=$toId, fromMsgNum=$fromMsgNum, toMsgNum=$toMsgNum');

        if (currentUserId == fromId && toMsgNum > 0) {
          foundNewMessage = false;
          appLog(' → Nouveau message détecté pour TESTET currentUserId $fromId');
          break;
        } else if (currentUserId == toId && toMsgNum > 0) {
          foundNewMessage = true;
          appLog(
              ' → je test la condition currentUserId == toId && toMsgNum > 0');
          break;
        } else if (currentUserId == toId && fromMsgNum > 0) {
          foundNewMessage = false;
          appLog(
              ' → je test la condition currentUserId == toId && fromMsgNum > 0');
          break;
        } else if (currentUserId == fromId && fromMsgNum > 0) {
          foundNewMessage = true;
          appLog(
              ' → je test la condition currentUserId == fromId && fromMsgNum > 0');
          break;
        }
      }

      _hasNewMessage = foundNewMessage;
      _hasNewMessageController.add(foundNewMessage);
      notifyListeners();

      appLog(
          '[MessageProvider.listenForMessages] hasNewMessage = $foundNewMessage');
    });
  }

  /// Pour reset le flag (ex: quand on ouvre la page messages)
  void clearNewMessageFlag() {
    appLog('[MessageProvider.clearNewMessageFlag] Reset du flag');
    _hasNewMessage = false;
    _hasNewMessageController.add(false);
    notifyListeners();
  }

  /// À appeler à la déconnexion : ce provider est global (créé une seule fois
  /// dans main.dart), il continuerait sinon à écouter les chats de
  /// l'utilisateur précédent après logout (permission-denied en boucle une
  /// fois les règles Firestore actives, puisque request.auth devient null).
  void reset() {
    appLog('[MessageProvider.reset] Annulation des écoutes en cours');
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _lastMessage = null;
    _hasNewMessage = false;
    _userFrom = null;
  }

  @override
  void dispose() {
    appLog('[MessageProvider.dispose] Dispose appelé');
    _chatSubscription?.cancel();
    _hasNewMessageController.close();
    super.dispose();
  }
}
