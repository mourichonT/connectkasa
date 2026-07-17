import 'package:konodal/core/providers/contact_repository_provider.dart';
import 'package:konodal/models/pages_models/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contacts ("Numéros utiles") d'une résidence (ContactView). Mis en
/// cache par Riverpod - contrairement à l'ancien fetch fait directement
/// dans build() (StatelessWidget), qui relançait la requête à chaque
/// reconstruction du widget.
final contactsByResidenceProvider =
    FutureProvider.family<List<Contact>, String>((ref, residenceId) async {
  final repository = ref.watch(contactRepositoryProvider);
  return repository
      .getContactsByResidence(residenceId)
      .then((result) => result.when(
          success: (v) => v, failure: (error) => throw error));
});
