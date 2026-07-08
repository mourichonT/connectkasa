import 'package:connect_kasa/core/repositories/chat_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return FirestoreChatRepository();
});
