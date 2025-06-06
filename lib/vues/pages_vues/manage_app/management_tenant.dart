import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/pages_controllers/tenant_controller.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/demande_loc.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail_withheader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManagementTenant extends StatefulWidget {
  final Color color;
  final String uid;

  const ManagementTenant({super.key, required this.color, required this.uid});

  @override
  ManagementTenantState createState() => ManagementTenantState();
}

class ManagementTenantState extends State<ManagementTenant>
    with SingleTickerProviderStateMixin {
  DataBasesUserServices userServices = DataBasesUserServices();
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();

  late Future<List<Lot?>> _lotByUser;
  late Future<List<DemandeLoc>> _allDemand;
  late Future<List<Map<String, dynamic>>> tenantsAndLots;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLotsByUser();
    _fetchDemande();
    tenantsAndLots = Future.value([]);
    initializeTenants();
  }

  Future<List<Lot?>> _fetchLotsByUser() async {
    _lotByUser = _databasesLotServices.getLotByIdUser(widget.uid);
    return await _lotByUser;
  }

  Future<List<DemandeLoc>> _fetchDemande() async {
    _allDemand = DataBasesUserServices.getDemande(widget.uid);

    return await _allDemand;
  }

  void initializeTenants() {
    tenantsAndLots = _lotByUser.then((lots) async {
      List<Future<Map<String, dynamic>>> userFutures = [];

      for (var lot in lots) {
        if (lot != null && lot.idLocataire != null) {
          for (var idLocataire in lot.idLocataire!) {
            if (idLocataire != widget.uid) {
              userFutures
                  .add(userServices.getUserWithInfo(idLocataire).then((user) {
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
          'Gestion des Locataires',
          Colors.black87,
          SizeFont.h1.size,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: widget.color,
          unselectedLabelColor: Colors.grey,
          indicatorColor: widget.color,
          tabs: const [
            Tab(text: 'Actuels'),
            Tab(text: 'Demande'),
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
                  return const Center(child: CircularProgressIndicator());
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
                        return const Center(child: CircularProgressIndicator());
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
                  return const Center(child: CircularProgressIndicator());
                } else if (demandesSnapshot.hasError) {
                  return Center(
                      child: Text('Erreur: ${demandesSnapshot.error}'));
                } else if (!demandesSnapshot.hasData ||
                    demandesSnapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucune demande trouvée.'));
                } else {
                  List<DemandeLoc> demandes = demandesSnapshot.data!;
                  return ListView.separated(
                    itemCount: demandes.length,
                    itemBuilder: (context, index) {
                      DemandeLoc demande = demandes[index];

                      return FutureBuilder<UserInfo?>(
                        future: userServices
                            .getUserWithInfo(demande.tenantId ?? ""),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const ListTile(
                              title: Text('Chargement du locataire...'),
                            );
                          }

                          final tenantInfo = snapshot.data!;
                          return ListTile(
                            leading: const Icon(Icons.mail_outline),
                            title: MyTextStyle.lotName(
                                '${tenantInfo.surname} ${tenantInfo.name}',
                                Colors.black87,
                                SizeFont.h3.size,
                                FontWeight.normal),
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
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          height: 50,
          color: Colors.transparent,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: ButtonAdd(
              function: () {},
              text: "Rattacher un locataire",
              color: widget.color,
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size,
            ),
          ),
        ),
      ),
    );
  }
}
