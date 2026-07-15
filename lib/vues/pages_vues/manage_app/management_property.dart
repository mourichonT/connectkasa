import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/handlers/colors_utils.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/pages_vues/manage_app/modify_propoerty.dart';
import 'package:konodal/vues/pages_vues/no_lot/attach_existing_lot_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class ManagementProperty extends ConsumerStatefulWidget {
  final String uid;
  final String idLot;
  final Color color;

  const ManagementProperty(
      {super.key,
      required this.color,
      required this.uid,
      required this.idLot});
  @override
  ConsumerState<ManagementProperty> createState() =>
      ManagementPropertyState();
}

class ManagementPropertyState extends ConsumerState<ManagementProperty> {
  late Color _backgroundColor;
  late Future<List<Lot?>> _lotByUser;
  late final ILotRepository _databasesLotServices;

  @override
  void initState() {
    _databasesLotServices = ref.read(lotRepositoryProvider);
    _lotByUser = _databasesLotServices
        .getLotByIdUser(widget.uid)
        .then((result) => result.when(
            success: _onlyApprovedLots, failure: (_) => <Lot>[]));
    super.initState();
  }

  // Un lot dont isApprovedLot est encore false n'a pas été vérifié
  // (justificatifs non validés) : il ne doit pas apparaître ici comme un
  // bien accessible, sous peine de laisser croire à un accès approuvé alors
  // qu'aucun contrôle n'a eu lieu. Un lot enfant groupé (groupedWithParent)
  // est fusionné avec son parent (même propriétaire ET même locataire) :
  // il ne doit plus apparaître comme un bien distinct tant qu'il reste
  // groupé (cf. project_lot_parent_child) - sa page de gestion propre
  // n'est alors plus atteignable, cette liste étant l'unique point d'entrée.
  List<Lot> _onlyApprovedLots(List<Lot> lots) => lots
      .where((lot) =>
          lot.userLotDetails['isApprovedLot'] == true &&
          !lot.groupedWithParent)
      .toList();

  Future<List<Lot?>> _fetchLotsByUser() async {
    _lotByUser = _databasesLotServices
        .getLotByIdUser(widget.uid)
        .then((result) => result.when(
            success: _onlyApprovedLots, failure: (_) => <Lot>[]));

    return await _lotByUser;
  }

  void _refreshData() {
    setState(() {
      _lotByUser =
          _fetchLotsByUser(); // Rafraîchissez le Future pour recharger les données
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            'Gestion des biens', Colors.black87, SizeFont.h1.size),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
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
              return ListView.separated(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  Lot? lot = snapshot.data![index];
                  //  bool loca = lot!.idLocataire!.contains(widget.uid);
                  _backgroundColor =
                      ColorUtils.fromHex(lot!.userLotDetails['colorSelected']);
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => ModifyProperty(
                            idLotSelected: widget.idLot,
                            lot: lot,
                            uid: widget.uid,
                            newColor: (Color newColor) {
                              _backgroundColor = newColor;
                            },
                          ),
                        ),
                      ).then((_) => _refreshData());
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _backgroundColor,
                        radius: 10, // Rayon du cercle
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape
                                .circle, // Définir la forme comme un cercle
                          ),
                        ),
                      ),
                      title: MyTextStyle.lotName(
                        lot.userLotDetails['nameLot'] == null ||
                                lot.userLotDetails['nameLot'] == ""
                            ? "${lot.residenceData["name"]} ${lot.batiment}${lot.lot}"
                            : lot.userLotDetails['nameLot'],
                        Colors.black87,
                        SizeFont.h2.size,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MyTextStyle.lotDesc(
                                  lot.residenceAddress["street"] ?? "",
                                  SizeFont.h3.size),
                              Container(
                                  padding: const EdgeInsets.only(left: 4)),
                            ],
                          ),
                          Row(
                            children: [
                              MyTextStyle.lotDesc(
                                  lot.residenceAddress["zipCode"] ?? "",
                                  SizeFont.h3.size),
                              Container(
                                  padding: const EdgeInsets.only(left: 4)),
                              MyTextStyle.lotDesc(
                                  lot.residenceAddress["city"] ?? "",
                                  SizeFont.h3.size),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF757575),
                        size: 22,
                      ),
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
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.only(bottom: 20),
        color: Colors.transparent,
        child: SizedBox(
          child: ButtonAdd(
              function: () async {
                final attached = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AttachExistingLotPage(
                      uid: widget.uid,
                    ),
                  ),
                );
                if (attached == true) {
                  _refreshData();
                }
              },
              icon: Icons.add,
              text: "Ajouter un lot",
              color: Theme.of(context).primaryColor,
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size),
        ),
      ),
    );
  }
}
