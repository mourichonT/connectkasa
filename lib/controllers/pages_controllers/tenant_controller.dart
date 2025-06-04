import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/demande_loc.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/guarantor_detail.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail_withheader.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';

class TenantController extends StatelessWidget {
  final UserInfo tenant;
  final String uid;
  final String? residenceId;
  final Color color;

  const TenantController({
    super.key,
    required this.tenant,
    required this.uid,
    this.residenceId,
    required this.color,
  });

  Future<List<DemandeLoc>> fetchDemandesLoc() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(uid)
        .collection('demandes_loc')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return DemandeLoc.fromJson(data);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: 400.0,
                toolbarHeight: 90,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCollapsed =
                        constraints.maxHeight <= kToolbarHeight + 195;
                    return FlexibleSpaceBar(
                      //centerTitle: false,
                      titlePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      title: isCollapsed
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  top: 0.0, bottom: 40, left: 30),
                              child: Row(
                                children: [
                                  ProfilTile(tenant.uid, 35, 30, 35, false),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    // ✅ Ajouté pour éviter l'overflow
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        MyTextStyle.lotDesc(
                                          "${tenant.name} ${tenant.surname}",
                                          SizeFont.h3.size,
                                          FontStyle.normal,
                                          FontWeight.bold,
                                        ),
                                        MyTextStyle.lotDesc(
                                          "@${tenant.pseudo}",
                                          SizeFont.h3.size,
                                          FontStyle.italic,
                                          FontWeight.normal,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(10),
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      maxHeight:
                                          230), // Ajuste cette valeur si nécessaire
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                          height: 10), // Réduit l’espace ici
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ProfilTile(
                                              tenant.uid, 55, 35, 55, false),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            MyTextStyle.postDesc(
                                                "${tenant.name} ${tenant.surname}",
                                                SizeFont.h3.size,
                                                Colors.black87,
                                                textAlign: TextAlign.center,
                                                fontweight: FontWeight.bold),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            MyTextStyle.lotDesc(
                                              "@${tenant.pseudo}",
                                              SizeFont.h3.size,
                                              FontStyle.italic,
                                              FontWeight.normal,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    );
                  },
                ),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Demandeur'),
                    Tab(text: 'Garant 1'),
                    Tab(text: 'Garant 2'),
                  ],
                ),
              ),
            ];
          },
          body: FutureBuilder<List<DemandeLoc>>(
            future: fetchDemandesLoc(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              final demandes = snapshot.data ?? [];
              final DemandeLoc? firstDemande =
                  demandes.isNotEmpty ? demandes[0] : null;
              final List<GuarantorInfo?> garants = firstDemande?.garant ?? [];

              return TabBarView(
                children: [
                  TenantDetail(
                    residenceId: residenceId,
                    senderUid: uid,
                    tenant: tenant,
                    color: color,
                  ),
                  garants.isNotEmpty && garants[0] != null
                      ? GuarantorDetail(garant: garants[0]!)
                      : const Center(child: Text("Aucun garant 1")),
                  garants.length > 1 && garants[1] != null
                      ? GuarantorDetail(garant: garants[1]!)
                      : const Center(child: Text("Aucun garant 2")),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
