import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/pages_controllers/tenant_controller.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:konodal/core/repositories/user_repository.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/demande_historique.dart';
import 'package:konodal/models/pages_models/demande_loc.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

// Élément unifié de l'onglet "Historique" (demande refusée OU ancien
// locataire), pour n'avoir qu'une seule liste triée par date au lieu de deux
// sections séparées - filtrable via les cases à cocher "Refusés"/"Anciens
// locataires".
class _HistoryItem {
  final DateTime date;
  final bool refused; // true: demande refusée : false: ancien locataire
  final DemandeHistorique? demande;
  final UserInfo? formerTenant;
  final Lot? formerLot;

  _HistoryItem.refused(DemandeHistorique d)
      : date = d.refusedAt?.toDate() ?? DateTime.now(),
        refused = true,
        demande = d,
        formerTenant = null,
        formerLot = null;

  _HistoryItem.former(this.formerTenant, this.formerLot, DateTime leftAt)
      : date = leftAt,
        refused = false,
        demande = null;
}

class ManagementTenant extends StatefulWidget {
  final Color color;
  final String uid;

  const ManagementTenant({super.key, required this.color, required this.uid});

  @override
  ManagementTenantState createState() => ManagementTenantState();
}

class ManagementTenantState extends State<ManagementTenant>
    with SingleTickerProviderStateMixin {
  IUserRepository userServices = FirestoreUserRepository();
  final ILotRepository _databasesLotServices = FirestoreLotRepository();

  late Future<List<Lot?>> _lotByUser;
  late Future<List<DemandeLoc>> _allDemand;
  late Future<List<Map<String, dynamic>>> tenantsAndLots;
  late Future<List<Map<String, dynamic>>> formerTenantsAndLots;
  late Future<List<DemandeHistorique>> _demandeHistorique;
  late Future<List<_HistoryItem>> _historyItems;
  late TabController _tabController;

  int _unseenDemandCount = 0;
  // Filtre de l'onglet "Historique" (case à cocher) : les deux activées par
  // défaut, une seule liste triée par date au lieu de deux sections.
  bool _showRefused = true;
  bool _showFormerTenants = true;

  // Cache par tenantId : sans ça, le Future passé à FutureBuilder dans
  // itemBuilder serait recréé (donc refetché) à chaque rebuild de l'onglet
  // "Demande", au lieu d'une seule fois - un rebuild déclenché ailleurs
  // (ex: providers Riverpod d'une page voisine) relançait alors la requête
  // en boucle. Devient particulièrement visible (app qui semble figée) une
  // fois une demande retirée : la requête échoue alors systématiquement
  // (PERMISSION_DENIED, pendingDemandeLandlords révoqué) et repart quand
  // même à chaque rebuild au lieu de rester en échec.
  final Map<String, Future<UserInfo?>> _demandeTenantInfoCache = {};

  Future<UserInfo?> _tenantInfoForDemande(String tenantId) {
    return _demandeTenantInfoCache.putIfAbsent(
      tenantId,
      () => userServices
          .getUserWithInfo(tenantId)
          .then((result) => result.when(success: (v) => v, failure: (_) => null)),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLotsByUser();
    _fetchDemande();
    tenantsAndLots = Future.value([]);
    formerTenantsAndLots = Future.value([]);
    _demandeHistorique = userServices
        .getDemandeHistorique(widget.uid)
        .then((result) => result.when(success: (v) => v, failure: (_) => []));
    initializeTenants();
    initializeFormerTenants();
    _historyItems = _computeHistoryItems();
  }

  // Fusionne demandes refusées + anciens locataires en une seule liste triée
  // par date (la plus récente en premier), filtrable via les cases à cocher
  // "Refusés"/"Anciens locataires" plutôt que deux sections séparées.
  Future<List<_HistoryItem>> _computeHistoryItems() async {
    final refusedList = await _demandeHistorique;
    final formerList = await formerTenantsAndLots;

    final items = <_HistoryItem>[
      ...refusedList.map((d) => _HistoryItem.refused(d)),
      ...formerList.map((entry) => _HistoryItem.former(
          entry['user'] as UserInfo?,
          entry['lot'] as Lot,
          (entry['leftAt'] as Timestamp).toDate())),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  // Rafraîchit la liste des locataires actuels + l'historique après une
  // révocation réussie depuis TenantDetail (l'onglet "Actuels" doit perdre
  // ce locataire, l'onglet "Historique" doit le gagner).
  void refreshTenantsList() {
    setState(() {
      _fetchLotsByUser();
      initializeTenants();
      initializeFormerTenants();
      _historyItems = _computeHistoryItems();
    });
  }

  Future<List<Lot?>> _fetchLotsByUser() async {
    _lotByUser = _databasesLotServices
        .getLotByIdUser(widget.uid)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]))
        .then((lots) {
      return lots.where((lot) {
        // Vérifie que le lot est non nul et que le uid est dans idProprietaire
        return lot.idProprietaire != null &&
            lot.idProprietaire!.contains(widget.uid);
      }).toList();
    });

    return await _lotByUser;
  }

  Future<List<DemandeLoc>> _fetchDemande() async {
    _allDemand = userServices
        .getDemande(widget.uid)
        .then((result) => result.when(
            success: (v) => v, failure: (error) => throw error));
    final demandes = await _allDemand;
    setState(() {
      _unseenDemandCount = demandes.where((d) => d.open == false).length;
    });

    return demandes;
  }

  void initializeTenants() {
    tenantsAndLots = _lotByUser.then((lots) async {
      List<Future<Map<String, dynamic>>> userFutures = [];

      for (var lot in lots) {
        if (lot != null && lot.idLocataire != null) {
          for (var idLocataire in lot.idLocataire!) {
            if (idLocataire != widget.uid) {
              userFutures.add(userServices
                  .getUserWithInfo(idLocataire)
                  .then((result) =>
                      result.when(success: (v) => v, failure: (_) => null))
                  .then((user) {
                return {'user': user, 'residence': lot.residenceId, 'lot': lot};
              }));
            }
          }
        } else {
          userFutures.add(Future.value({'user': null, 'lot': lot}));
        }
      }

      return Future.wait(userFutures);
    });
  }

  // Historique (onglet "Historique") : un ancien locataire par entrée de
  // Lot.idLocataireOld, avec la date à laquelle il a quitté ce lot.
  void initializeFormerTenants() {
    formerTenantsAndLots = _lotByUser.then((lots) async {
      List<Future<Map<String, dynamic>>> userFutures = [];

      for (var lot in lots) {
        if (lot != null) {
          for (var former in lot.idLocataireOld) {
            userFutures.add(userServices
                .getUserWithInfo(former.uid)
                .then((result) =>
                    result.when(success: (v) => v, failure: (_) => null))
                .then((user) {
              return {'user': user, 'lot': lot, 'leftAt': former.leftAt};
            }));
          }
        }
      }

      // Plus récent en premier.
      final results = await Future.wait(userFutures);
      results.sort((a, b) =>
          (b['leftAt'] as Timestamp).compareTo(a['leftAt'] as Timestamp));
      return results;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          'Gestion des locataires',
          Colors.black87,
          SizeFont.h1.size,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: widget.color,
          unselectedLabelColor: Colors.grey,
          indicatorColor: widget.color,
          tabs: [
            const Tab(text: 'Actuels'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Demandes'),
                  if (_unseenDemandCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unseenDemandCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1 : Actuels
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: FutureBuilder<List<Lot?>>(
              future: _lotByUser,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoader());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun bien trouvé.'));
                } else {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: tenantsAndLots,
                    builder: (context, tenantsSnapshot) {
                      if (tenantsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: AppLoader());
                      } else if (tenantsSnapshot.hasError) {
                        return Center(
                            child: Text('Erreur: ${tenantsSnapshot.error}'));
                      } else if (!tenantsSnapshot.hasData ||
                          tenantsSnapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('Aucun locataire trouvé.'));
                      } else {
                        List<Map<String, dynamic>> tenants =
                            tenantsSnapshot.data!;
                        return ListView.separated(
                          itemCount: tenants.length,
                          itemBuilder: (context, index) {
                            var tenantMap = tenants[index];
                            UserInfo? tenant = tenantMap['user'];
                            Lot? lot = tenantMap['lot'];
                            String? lotName = lot!.userLotDetails["nameLot"];
                            String? showLotName = (lotName == "" ||
                                    lotName == null)
                                ? "${lot.residenceData["name"]} ${lot.batiment} ${lot.lot}"
                                : lotName;
                            if (tenant == null) {
                              return const ListTile(
                                  title: Text('Locataire non trouvé.'));
                            }
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => TenantController(
                                      tenant: tenant,
                                      color: widget.color,
                                      uid: widget.uid,
                                      residenceId: tenantMap['residence'],
                                      lotId: lot.id,
                                      refreshTenants: refreshTenantsList,
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: const Icon(Icons.person_2_outlined),
                                title: MyTextStyle.lotName(
                                  "${tenant.surname} ${tenant.name}",
                                  Colors.black87,
                                  SizeFont.h3.size,
                                ),
                                subtitle: Text('Lot: $showLotName'),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    color: Color(0xFF757575), size: 22),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const Divider(thickness: 0.7),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),

          // Tab 2 : Demande
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: FutureBuilder<List<DemandeLoc>>(
              future: _allDemand,
              builder: (context, demandesSnapshot) {
                if (demandesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: AppLoader(size: 60));
                } else if (demandesSnapshot.hasError) {
                  return Center(
                      child: Text('Erreur: ${demandesSnapshot.error}'));
                } else if (!demandesSnapshot.hasData ||
                    demandesSnapshot.data!
                        .where((d) => !d.refused)
                        .isEmpty) {
                  return const Center(child: Text('Aucune demande trouvée.'));
                } else {
                  // Une demande refusée reste en base (cf. refuseDemande,
                  // pour que le locataire voie le statut) mais ne doit plus
                  // apparaître ici comme "active" - seulement dans
                  // l'onglet "Historique".
                  List<DemandeLoc> demandes =
                      demandesSnapshot.data!.where((d) => !d.refused).toList();
                  demandes.sort((a, b) {
                    if (a.open == b.open) {
                      return a.timestamp!.compareTo(b.timestamp!);
                    } else if (!a.open) {
                      return -1;
                    } else {
                      return 1;
                    }
                  });
                  return ListView.separated(
                    itemCount: demandes.length,
                    itemBuilder: (context, index) {
                      final demande = demandes[index];
                      final demandeId =
                          demandesSnapshot.data![index].id; // <-- À ajouter

                      return FutureBuilder<UserInfo?>(
                        future: _tenantInfoForDemande(demande.tenantId ?? ""),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: AppLoader(size: 30)),
                            );
                          }

                          final tenantInfo = snapshot.data!;
                          final lotInfo = demande.lotAddress?.isNotEmpty == true
                              ? "${demande.lotAddress}"
                                  "${demande.lotNumero?.isNotEmpty == true ? ' (lot ${demande.lotNumero})' : ''}"
                              : null;
                          return ListTile(
                            leading: const Icon(Icons.mail_outline),
                            title: MyTextStyle.lotName(
                                '${tenantInfo.surname} ${tenantInfo.name}',
                                Colors.black87,
                                SizeFont.h3.size,
                                !demande.open
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                            subtitle: lotInfo != null
                                ? MyTextStyle.lotDesc(lotInfo, SizeFont.h3.size,
                                    FontStyle.normal, FontWeight.normal, Colors.black54)
                                : null,
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => TenantController(
                                    tenant: tenantInfo,
                                    color: widget.color,
                                    uid: widget.uid,
                                    residenceId: '',
                                    refreshUnseeCounter:
                                        refreshUnseenDemandCount,
                                    demandeId: demandeId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(thickness: 0.7),
                  );
                }
              },
            ),
          ),

          // Tab 3 : Historique (demandes refusées + anciens locataires,
          // une seule liste triée par date, filtrable par case à cocher).
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _showRefused,
                        title: const Text('Refusés'),
                        onChanged: (value) => setState(
                            () => _showRefused = value ?? true),
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _showFormerTenants,
                        title: const Text('Anciens locataires'),
                        onChanged: (value) => setState(
                            () => _showFormerTenants = value ?? true),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<_HistoryItem>>(
                    future: _historyItems,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: AppLoader());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text('Erreur: ${snapshot.error}'));
                      }
                      final items = (snapshot.data ?? [])
                          .where((i) => i.refused
                              ? _showRefused
                              : _showFormerTenants)
                          .toList();
                      if (items.isEmpty) {
                        return const Center(
                            child: Text('Aucun élément à afficher.'));
                      }
                      return ListView.separated(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          if (item.refused) {
                            final d = item.demande!;
                            final lotInfo = d.lotAddress?.isNotEmpty == true
                                ? "${d.lotAddress}"
                                    "${d.lotNumero?.isNotEmpty == true ? ' (lot ${d.lotNumero})' : ''}"
                                : null;
                            return ListTile(
                              leading:
                                  Icon(Icons.block, color: Colors.red[800]),
                              title: MyTextStyle.lotName(
                                "${d.tenantSurname} ${d.tenantName}",
                                Colors.black87,
                                SizeFont.h3.size,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (lotInfo != null) Text(lotInfo),
                                  if (d.submittedAt != null)
                                    Text('Soumis le ${DateFormat('dd/MM/yyyy').format(d.submittedAt!.toDate())}'),
                                  if (d.refusedAt != null)
                                    Text('Refusé le ${DateFormat('dd/MM/yyyy').format(d.refusedAt!.toDate())}'),
                                  Text('Motif : ${d.refusalReason}',
                                      style: TextStyle(
                                          color: Colors.red[800],
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          } else {
                            final tenant = item.formerTenant;
                            final lot = item.formerLot!;
                            final lotName = lot.userLotDetails["nameLot"];
                            final showLotName = (lotName == "" ||
                                    lotName == null)
                                ? "${lot.residenceData["name"]} ${lot.batiment} ${lot.lot}"
                                : lotName;
                            return ListTile(
                              leading: const Icon(Icons.history),
                              title: MyTextStyle.lotName(
                                tenant != null
                                    ? "${tenant.surname} ${tenant.name}"
                                    : "Locataire non trouvé",
                                Colors.black87,
                                SizeFont.h3.size,
                              ),
                              subtitle: Text(
                                  'Lot: $showLotName - Parti le ${DateFormat('dd/MM/yyyy').format(item.date)}'),
                            );
                          }
                        },
                        separatorBuilder: (context, index) =>
                            const Divider(thickness: 0.7),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void refreshUnseenDemandCount() {
    _fetchDemande(); // Cette méthode recharge les demandes et met à jour _unseenDemandCount
    // Un refus (TenantDetail) crée une nouvelle entrée demandes_historique :
    // sans ça, l'onglet "Historique" ne l'affiche qu'après un rechargement
    // complet de l'app (_demandeHistorique/_historyItems ne sont fetchés
    // qu'une fois, dans initState).
    setState(() {
      _demandeHistorique = userServices
          .getDemandeHistorique(widget.uid)
          .then((result) => result.when(success: (v) => v, failure: (_) => []));
      _historyItems = _computeHistoryItems();
    });
  }
}
