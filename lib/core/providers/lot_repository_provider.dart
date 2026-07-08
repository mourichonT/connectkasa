import 'package:connect_kasa/core/repositories/lot_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_lot_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lotRepositoryProvider = Provider<ILotRepository>((ref) {
  return FirestoreLotRepository();
});
