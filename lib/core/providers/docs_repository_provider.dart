import 'package:konodal/core/repositories/docs_repository.dart';
import 'package:konodal/core/repositories/firestore_docs_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final docsRepositoryProvider = Provider<IDocsRepository>((ref) {
  return FirestoreDocsRepository();
});
