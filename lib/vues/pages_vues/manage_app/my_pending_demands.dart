import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/current_user_provider.dart';
import 'package:konodal/core/providers/demande_providers.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/demande_loc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class MyPendingDemands extends ConsumerWidget {
  final String uid;
  final Color color;

  const MyPendingDemands({super.key, required this.uid, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandesAsync = ref.watch(sentDemandesProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            'Mes demandes en cours', Colors.black87, SizeFont.h1.size),
      ),
      body: demandesAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) => Center(child: Text('Erreur : $error')),
        data: (demandes) {
          if (demandes.isEmpty) {
            return const Center(child: Text('Aucune demande en cours.'));
          }
          return ListView.separated(
            itemCount: demandes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              return _DemandeTile(
                demande: demandes[index],
                tenantUid: uid,
                onWithdrawn: () => ref.invalidate(sentDemandesProvider(uid)),
              );
            },
          );
        },
      ),
    );
  }
}

class _DemandeTile extends ConsumerWidget {
  final DemandeLoc demande;
  final String tenantUid;
  final VoidCallback onWithdrawn;

  const _DemandeTile({
    required this.demande,
    required this.tenantUid,
    required this.onWithdrawn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landlordAsync = ref.watch(userByIdProvider(demande.landlordId ?? ''));

    return ListTile(
      leading: const Icon(Icons.mail_outline),
      title: landlordAsync.when(
        loading: () => MyTextStyle.lotName(
            'Chargement...', Colors.black87, SizeFont.h3.size),
        error: (error, stackTrace) => MyTextStyle.lotName(
            'Propriétaire inconnu', Colors.black87, SizeFont.h3.size),
        data: (landlord) => MyTextStyle.lotName(
          landlord != null
              ? '${landlord.name} ${landlord.surname}'
              : 'Propriétaire inconnu',
          Colors.black87,
          SizeFont.h3.size,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            demande.refused
                ? 'Refusé'
                : (demande.open ? 'Consultée par le bailleur' : 'En attente'),
            style: TextStyle(
              color: demande.refused ? Colors.red[800] : Colors.black54,
              fontWeight:
                  demande.refused ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (demande.lotAddress?.isNotEmpty == true)
            Text(
              "${demande.lotAddress}"
                  "${demande.lotNumero?.isNotEmpty == true ? ' (lot ${demande.lotNumero})' : ''}",
              style: const TextStyle(color: Colors.black54),
            ),
          if (demande.refused && demande.refusalReason?.isNotEmpty == true)
            Text(
              'Motif : ${demande.refusalReason}',
              style: TextStyle(color: Colors.red[800]),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        tooltip: 'Retirer la demande',
        onPressed: () => _confirmWithdraw(context, ref),
      ),
    );
  }

  Future<void> _confirmWithdraw(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: MyTextStyle.lotName(
            'Retirer la demande', Colors.black87, SizeFont.h2.size),
        content: MyTextStyle.lotDesc(
          "Si vous supprimez cette demande, le bailleur perdra "
          "immédiatement l'accès à votre dossier et ne pourra plus le "
          "consulter. Êtes-vous certain de vouloir continuer ?",
          SizeFont.h3.size,
          FontStyle.normal,
          FontWeight.normal,
          Colors.black54,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: MyTextStyle.lotName(
                'Annuler', Colors.black54, SizeFont.h3.size, FontWeight.normal),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: MyTextStyle.lotName(
                'Retirer', Colors.red, SizeFont.h3.size, FontWeight.normal),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (demande.landlordId == null || demande.id == null) return;

    final repository = ref.read(userRepositoryProvider);
    final result = await repository.withdrawDemande(
      tenantUid: tenantUid,
      landlordId: demande.landlordId!,
      demandeId: demande.id!,
    );
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande retirée')),
        );
        onWithdrawn();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      ),
    );
  }
}
