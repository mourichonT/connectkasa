import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_docs_services.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/demande_loc.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/components/look_up_user.dart';
import 'package:flutter/material.dart';

class ShareRentFolder {
  static Future<List<GuarantorInfo>> showGuarantorSelectionDialog(
      BuildContext context, String uid, String docId) async {
    DemandeLoc demande = DemandeLoc();
    List<GuarantorInfo> allGarants =
        await DataBasesUserServices.getGarants(uid, docId);
    List<String> selected = [];

    print('Garants disponibles:');
    allGarants.forEach((g) {
      print('Garant: ${g.name} ${g.surname} - ${g.email}');
    });

    return await showDialog<List<GuarantorInfo>>(
          context: context,
          builder: (context) {
            List<GuarantorInfo> selected = [];

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: MyTextStyle.lotName('Sélectionnez 2 garants',
                      Colors.black87, SizeFont.h1.size, FontWeight.bold),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: allGarants.map((g) {
                        bool isSelected = selected.contains(g);
                        return CheckboxListTile(
                          title: MyTextStyle.lotName(
                              '${g.name} ${g.surname}',
                              Colors.black87,
                              SizeFont.h3.size,
                              FontWeight.normal),
                          subtitle: Text(g.email),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (selected.length <= 1) {
                                  selected.add(g);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Vous ne pouvez sélectionner que 2 garants.'),
                                    duration: Duration(seconds: 2),
                                  ));
                                }
                              } else {
                                selected.remove(g);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context, selected);
                        List<String>? selectedGarantIds =
                            selected.map((g) => g.id!).toList();

                        demande = DemandeLoc(
                          timestamp: Timestamp.now(),
                          tenantId: uid,
                          garantId: selectedGarantIds,
                        );
                        await LookUpUser.searchUserForm(context, demande);
                      },
                      child: Text('Valider'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        [];
  }

  static Future<void> showLotSelectionDialog(
      BuildContext context, String userId, String idLocataire) async {
    final DataBasesLotServices _dataBasesLotServices = DataBasesLotServices();

    List<Lot> lots = await _dataBasesLotServices
        .getLotByIdUser(userId); // récupère les lots liés à l'user

    Lot? selectedLot;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: MyTextStyle.lotName(
              "Sélectionner un lot", Colors.black87, SizeFont.h2.size),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: lots.length,
              itemBuilder: (context, index) {
                final lot = lots[index];
                return RadioListTile<Lot>(
                  title: MyTextStyle.lotName(
                      lot.userLotDetails['nameLot'] == null ||
                              lot.userLotDetails['nameLot'] == ""
                          ? "${lot.residenceData["name"]} ${lot.batiment}${lot.lot}"
                          : lot.userLotDetails['nameLot'],
                      Colors.black87,
                      SizeFont.h3.size,
                      FontWeight.normal),
                  value: lot,
                  groupValue: selectedLot,
                  onChanged: (Lot? value) {
                    selectedLot = value;
                    // force rebuild to update the Radio selection
                    (context as Element).markNeedsBuild();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                if (selectedLot != null) {
                  // On met à jour le lot sélectionné
                  await _dataBasesLotServices.addTenant(
                    context,
                    selectedLot!.residenceId,
                    selectedLot!.refLot,
                    // champ à mettre à jour
                    idLocataire, // id du locataire à ajouter
                  );
                  Navigator.of(context).pop(); // ferme le dialog
                } else {
                  // Optionnel : afficher un message d'erreur si aucun lot sélectionné
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Veuillez sélectionner un lot")),
                  );
                }
              },
              child: Text("Valider"),
            ),
          ],
        );
      },
    );
  }
}
