import 'package:connect_kasa/core/repositories/docs_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_docs_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final docsRepositoryProvider = Provider<IDocsRepository>((ref) {
  return FirestoreDocsRepository();
});
