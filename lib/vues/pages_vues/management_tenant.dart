import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/tenant_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManagementTenant extends StatefulWidget {
  final Future<List<Lot?>> lotByUser;
  final Color color;
  final String uid;

  const ManagementTenant(
      {super.key,
      required this.lotByUser,
      required this.color,
      required this.uid});

  @override
  ManagementTenantState createState() => ManagementTenantState();
}

class ManagementTenantState extends State<ManagementTenant> {
  DataBasesUserServices userServices = DataBasesUserServices();
  late Future<List<Map<String, dynamic>>> tenantsAndLots;

  @override
  void initState() {
    super.initState();
    tenantsAndLots = Future.value([]); // Initialize with an empty future
    initializeTenants();
  }

  void initializeTenants() {
    tenantsAndLots = widget.lotByUser.then((lots) async {
      List<Future<Map<String, dynamic>>> userFutures = [];

      for (var lot in lots) {
        if (lot != null && lot.idLocataire != null) {
          for (var idLocataire in lot.idLocataire!) {
            if (idLocataire != widget.uid) {
              // Exclude the current user
              userFutures
                  .add(userServices.getUserWithInfo(idLocataire).then((user) {
                return {
                  'user': user,
                  'lotName': lot.nameProp,
                  'residence': lot.residenceId // Assuming Lot has a `nameProp` field
                };
              }));
            }
          }
        } else {
          userFutures
              .add(Future.value({'user': null, 'lotName': lot?.nameProp}));
        }
      }

      return Future.wait(userFutures);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            'Gestion des Locataires', Colors.black87, SizeFont.h1.size),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: FutureBuilder<List<Lot?>>(
          future: widget.lotByUser,
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
                    return const Center(child: Text('Aucun locataire trouvé.'));
                  } else {
                    List<Map<String, dynamic>> tenants = tenantsSnapshot.data!;
                    return ListView.separated(
                      itemCount: tenants.length,
                      itemBuilder: (context, index) {
                        var tenantMap = tenants[index];
                        UserInfo? tenant = tenantMap['user'];
                        String? lotName = tenantMap['lotName'];
                        if (tenant == null) {
                          return const ListTile(title: Text('Locataire non trouvé.'));
                        }
                        return InkWell(
                          onTap: () {

                            Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => TenantDetail(residenceId: tenantMap['residence'], senderUid: widget.uid, tenant: tenant, color: widget.color,)));
                          },
                          child: ListTile(
                            leading: const Icon(Icons.person_2_outlined),
                            title: MyTextStyle.lotName(
                                "${tenant.surname} ${tenant.name}",
                                Colors.black87,
                                SizeFont.h3
                                    .size), // Assuming User has a `name` field
                            subtitle:
                                Text('Lot: $lotName'), // Displaying lot name
                            trailing: const Icon(
                              Icons.arrow_right_outlined,
                              size: 30,
                            ), // Assuming User has an `id` field
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(
                        thickness: 0.7,
                      ),
                    );
                  }
                },
              );
            }
          },
        ),
      ),
      bottomSheet: Container(
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
    );
  }
}
