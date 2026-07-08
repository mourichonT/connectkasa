import 'package:connect_kasa/core/repositories/post_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_post_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final postRepositoryProvider = Provider<IPostRepository>((ref) {
  return FirestorePostRepository();
});
