import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:flutter/material.dart';

class RentFolderController {
  Future<List<GuarantorInfo>> showGuarantorSelectionDialog(
      BuildContext context, String uid, String docId) async {
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
                                if (selected.length <= 2) {
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
                      onPressed: () =>
                          Navigator.pop<List<GuarantorInfo>>(context, []),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context, selected);
                        // await DataBasesUserServices.shareFile(demande, uid);
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
}
