import 'package:konodal/core/repositories/firestore_agency_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/agency.dart';
import 'package:konodal/models/pages_models/gerance_ref.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/card_contact_view.dart';
import 'package:flutter/material.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

/// Affiche le contact syndic (résidence/bâtiment) ou gérance locative (lot).
/// Prend directement soit une Agency déjà résolue (cas custom, non
/// référencée), soit une GeranceRef à résoudre depuis gerances (cas
/// référencé) : jamais les deux en même temps, cf. le contrat
/// geranceRef/syndicAgency posé sur Residence/StructureResidence/Lot.
class CardContactController extends StatelessWidget {
  final Lot selectedlot;
  final Agency? agency;
  final GeranceRef? geranceRef;
  final String uid;

  const CardContactController({
    super.key,
    required this.selectedlot,
    required this.uid,
    this.agency,
    this.geranceRef,
  });

  @override
  Widget build(BuildContext context) {
    if (geranceRef != null) {
      return FutureBuilder<Result<Agency?>>(
        future: FirestoreAgencyRepository().resolveRef(geranceRef!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoader());
          }
          final resolvedAgency = snapshot.data
              ?.when(success: (agency) => agency, failure: (_) => null);
          return _buildCard(resolvedAgency);
        },
      );
    }
    return _buildCard(agency);
  }

  Widget _buildCard(Agency? resolvedAgency) {
    if (resolvedAgency == null) {
      return const Center(child: Text('Agence introuvable'));
    }

    final syndic = resolvedAgency.syndic;
    final agents = syndic?.agents ?? [];
    final accountant = agents.isNotEmpty ? agents.first : null;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: CardContactView(
        selectedlot: selectedlot,
        accountantName: accountant?.nameAgent ?? '',
        accountantSurname: accountant?.surnameAgent ?? '',
        accountantPhone: accountant?.phone ?? syndic?.phone ?? '',
        accountantMail: accountant?.mail ?? syndic?.mail ?? '',
        accountantFonction: 'syndic',
        agencyName: resolvedAgency.name,
        agencystreet: resolvedAgency.street,
        agencyNum: resolvedAgency.numeros,
        agencyVoie: resolvedAgency.voie,
        agencyZIPCode: resolvedAgency.zipCode,
        agencyCity: resolvedAgency.city,
        uid: uid,
        accountantId: resolvedAgency.id,
      ),
    );
  }
}
