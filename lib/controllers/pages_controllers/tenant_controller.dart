import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/demande_loc.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/guarantor_detail.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';

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
      return DemandeLoc.fromJson(doc.data());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DemandeLoc>>(
      future: fetchDemandesLoc(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Erreur : ${snapshot.error}')),
          );
        }

        final demandes = snapshot.data ?? [];
        final DemandeLoc? firstDemande =
            demandes.isNotEmpty ? demandes.first : null;
        final List<String>? garants = firstDemande?.garantId ?? [];
        //final List<GuarantorInfo?> garants = firstDemande?.garant ?? [];

        final tabs = <Tab>[
          Tab(text: residenceId!.isNotEmpty ? 'Locataire' : 'Demandeur'),
          if (garants!.isNotEmpty) const Tab(text: 'Garant 1'),
          if (garants.length > 1) const Tab(text: 'Garant 2'),
        ];

        final tabViews = <Widget>[
          TenantDetail(
            residenceId: residenceId,
            senderUid: uid,
            tenant: tenant,
            color: color,
          ),
          if (garants.isNotEmpty && garants[0] != null)
            GuarantorDetail(tenantUid: tenant.uid, garantid: garants[0]!)
          else
            const Center(child: Text("Aucun garant 1")),
          if (garants.length > 1 && garants[1] != null)
            GuarantorDetail(tenantUid: tenant.uid, garantid: garants[1]!)
          else if (garants.length > 1)
            const Center(child: Text("Aucun garant 2")),
        ];

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 400,
                  toolbarHeight: 90,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCollapsed =
                          constraints.maxHeight <= kToolbarHeight + 195;
                      return FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        title: isCollapsed
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    top: 0, bottom: 40, left: 30),
                                child: Row(
                                  children: [
                                    ProfilTile(tenant.uid, 35, 30, 35, false),
                                    const SizedBox(width: 10),
                                    Expanded(
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
                                    constraints:
                                        const BoxConstraints(maxHeight: 230),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
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
                                            children: [
                                              MyTextStyle.postDesc(
                                                "${tenant.name} ${tenant.surname}",
                                                SizeFont.h3.size,
                                                Colors.black87,
                                                textAlign: TextAlign.center,
                                                fontweight: FontWeight.bold,
                                              ),
                                              const SizedBox(height: 5),
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
                  bottom: TabBar(tabs: tabs),
                ),
              ],
              body: TabBarView(children: tabViews),
            ),
          ),
        );
      },
    );
  }
}
