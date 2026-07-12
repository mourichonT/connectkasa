import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lotRepositoryProvider = Provider<ILotRepository>((ref) {
  return FirestoreLotRepository();
});
