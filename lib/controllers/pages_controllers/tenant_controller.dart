import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:flutter/material.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/guarantor_info.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:konodal/vues/pages_vues/manage_app/guarantor_detail.dart';
import 'package:konodal/vues/pages_vues/manage_app/tenant_detail.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class TenantController extends StatefulWidget {
  final UserInfo tenant;
  final String uid;
  final String? residenceId;
  // ID du lot (residences/{residenceId}/lot/{lotId}) occupé par ce
  // locataire - nécessaire pour révoquer son accès de manière scopée à ce
  // seul lot (removeIdLocataire), plutôt que de tous ses lots. Absent pour
  // une simple demande de location pas encore acceptée.
  final String? lotId;
  final Color color;
  final Function()? refreshUnseeCounter;
  // Rafraîchit la liste des locataires de ManagementTenant après une
  // révocation réussie depuis TenantDetail.
  final Function()? refreshTenants;
  final String? demandeId;

  const TenantController({
    super.key,
    required this.tenant,
    required this.uid,
    this.residenceId,
    this.lotId,
    required this.color,
    this.refreshUnseeCounter,
    this.refreshTenants,
    this.demandeId,
  });

  @override
  State<TenantController> createState() => _TenantControllerState();
}

class _TenantControllerState extends State<TenantController> {
  // Garants du LOCATAIRE lui-même (users/{tenant.uid}/garants), pas dérivés
  // de demandes_loc.garantId : cette dernière est supprimée dès qu'une
  // demande est acceptée (cf. _addTenantToLot) et n'est de toute façon pas
  // scopée à un tenant précis (fetchDemandesLoc lisait TOUTES les demandes
  // du bailleur et prenait arbitrairement la première) - une fois le
  // locataire accepté, ses garants disparaissaient donc des onglets.
  late Future<List<GuarantorInfo>> _garantsFuture;

  @override
  void initState() {
    super.initState();
    _garantsFuture = FirestoreUserRepository()
        .getGarants(widget.tenant.uid)
        .then((result) => result.when(success: (v) => v, failure: (_) => []));
    if (widget.demandeId != null && widget.demandeId!.isNotEmpty) {
      openDemande();
      appLog("demandeID : ${widget.demandeId}");
    }
  }

  Future<void> openDemande() async {
    await FirestoreUserRepository()
        .markDemandeAsRead(widget.uid, widget.demandeId!)
        .then((result) => result.when(
            success: (_) {},
            failure: (error) => appLog(
                "Erreur lors du marquage de la demande comme lue : $error")));
    widget.refreshUnseeCounter?.call(); // Appelle la fonction callback du parent
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GuarantorInfo>>(
      future: _garantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: AppLoader()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Erreur : ${snapshot.error}')),
          );
        }

        final List<String> garants = (snapshot.data ?? [])
            .map((g) => g.id)
            .whereType<String>()
            .toList();

        // hasGarant1/hasGarant2 pilotent à la fois `tabs` et `tabViews` : ces
        // deux listes doivent impérativement avoir la même longueur, sinon
        // DefaultTabController(length: tabs.length) et TabBarView(children:
        // tabViews) se désynchronisent. Cette assertion n'est vérifiée qu'en
        // debug (désactivée en release) : en production le mismatch ne
        // plantait pas mais figeait l'écran silencieusement (cas du
        // locataire sans aucun garant : tabs.length=1 vs tabViews.length=2
        // avant ce fix).
        final hasGarant1 = garants.isNotEmpty;
        final hasGarant2 = garants.length > 1;

        final tabs = <Tab>[
          Tab(
              text:
                  (widget.residenceId != null && widget.residenceId!.isNotEmpty)
                      ? 'Locataire'
                      : 'Demandeur'),
          if (hasGarant1) const Tab(text: 'Garant 1'),
          if (hasGarant2) const Tab(text: 'Garant 2'),
        ];

        final tabViews = <Widget>[
          TenantDetail(
            demandeId: widget.demandeId,
            residenceId: widget.residenceId,
            lotId: widget.lotId,
            senderUid: widget.uid,
            tenant: widget.tenant,
            color: widget.color,
            refreshUnseeCounter: widget.refreshUnseeCounter,
            refreshTenants: widget.refreshTenants,
          ),
          if (hasGarant1)
            GuarantorDetail(tenantUid: widget.tenant.uid, garantid: garants[0]),
          if (hasGarant2)
            GuarantorDetail(tenantUid: widget.tenant.uid, garantid: garants[1]),
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
                                    profilTile(
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
                                            profilTile(widget.tenant.uid, 55,
                                                50, 55, false),
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
