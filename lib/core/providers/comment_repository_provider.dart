import 'package:connect_kasa/core/repositories/comment_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_comment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final commentRepositoryProvider = Provider<ICommentRepository>((ref) {
  return FirestoreCommentRepository();
});
