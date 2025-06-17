import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/demande_loc.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/guarantor_detail.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';

class TenantController extends StatefulWidget {
  final UserInfo tenant;
  final String uid;
  final String? residenceId;
  final Color color;
  Function()? refreshUnseeCounter;
  final String? demandeId;

  TenantController({
    super.key,
    required this.tenant,
    required this.uid,
    this.residenceId,
    required this.color,
    this.refreshUnseeCounter,
    this.demandeId,
  });

  @override
  State<TenantController> createState() => _TenantControllerState();
}

class _TenantControllerState extends State<TenantController> {
  late Future<List<DemandeLoc>> _demandesFuture;

  @override
  void initState() {
    super.initState();
    _demandesFuture = fetchDemandesLoc();
    if (widget.demandeId != null && widget.demandeId!.isNotEmpty) {
      openDemande();
      print("demandeID : ${widget.demandeId}");
    }
  }

  Future<void> openDemande() async {
    await DataBasesUserServices.markDemandeAsRead(
        widget.uid, widget.demandeId!);
    widget.refreshUnseeCounter!(); // Appelle la fonction callback du parent
  }

  Future<List<DemandeLoc>> fetchDemandesLoc() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(widget.uid)
        .collection('demandes_loc')
        .get();

    return snapshot.docs.map((doc) {
      return DemandeLoc.fromJson(doc.data(), id: doc.id);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DemandeLoc>>(
      future: _demandesFuture,
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

        final tabs = <Tab>[
          Tab(
              text:
                  (widget.residenceId != null && widget.residenceId!.isNotEmpty)
                      ? 'Locataire'
                      : 'Demandeur'),
          if (garants!.isNotEmpty) const Tab(text: 'Garant 1'),
          if (garants.length > 1) const Tab(text: 'Garant 2'),
        ];

        final tabViews = <Widget>[
          TenantDetail(
            demandeId: widget.demandeId,
            residenceId: widget.residenceId,
            senderUid: widget.uid,
            tenant: widget.tenant,
            color: widget.color,
            refreshUnseeCounter: widget.refreshUnseeCounter,
          ),
          if (garants.isNotEmpty && garants[0] != null)
            GuarantorDetail(tenantUid: widget.tenant.uid, garantid: garants[0]!)
          else
            const Center(child: Text("Aucun garant 1")),
          if (garants.length > 1 && garants[1] != null)
            GuarantorDetail(tenantUid: widget.tenant.uid, garantid: garants[1]!)
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
                                    ProfilTile(
                                        widget.tenant.uid, 35, 30, 35, false),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MyTextStyle.lotDesc(
                                            "${widget.tenant.name} ${widget.tenant.surname}",
                                            SizeFont.h3.size,
                                            FontStyle.normal,
                                            FontWeight.bold,
                                          ),
                                          MyTextStyle.lotDesc(
                                            "@${widget.tenant.pseudo}",
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
                                            ProfilTile(widget.tenant.uid, 55,
                                                35, 55, false),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: Column(
                                            children: [
                                              MyTextStyle.postDesc(
                                                "${widget.tenant.name} ${widget.tenant.surname}",
                                                SizeFont.h3.size,
                                                Colors.black87,
                                                textAlign: TextAlign.center,
                                                fontweight: FontWeight.bold,
                                              ),
                                              const SizedBox(height: 5),
                                              MyTextStyle.lotDesc(
                                                "@${widget.tenant.pseudo}",
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
