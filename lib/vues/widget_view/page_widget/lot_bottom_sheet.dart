// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/lot_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/pages_models/lot.dart';

// LotBottomSheet (modifié)
class LotBottomSheet extends StatefulWidget {
  // remplace onRefresh par onLotSelected
  final void Function(Lot selectedLot)? onLotSelected;
  final Lot? selectedLot;
  final String uid;
  final List<Lot> lots;

  const LotBottomSheet({
    super.key,
    this.onLotSelected,
    this.selectedLot,
    required this.uid,
    required this.lots,
  });

  @override
  _LotBottomSheetState createState() => _LotBottomSheetState();
}

class _LotBottomSheetState extends State<LotBottomSheet> {
  Lot? preferedLot;
  int? selectedLotIndexLocal;

  final LoadPreferedData _loadPreferedData = LoadPreferedData();

  @override
  void initState() {
    super.initState();
    _initializeSelectedLot();
  }

  Future<void> _initializeSelectedLot() async {
    preferedLot =
        widget.selectedLot ?? await _loadPreferedData.loadPreferedLot();

    setState(() {
      selectedLotIndexLocal = findLotInArray(widget.lots);
    });
  }

  int? findLotInArray(List<Lot> lots) {
    final currentLot = widget.selectedLot ?? preferedLot;
    if (currentLot != null) {
      return lots.indexWhere((element) => element.refLot == currentLot.refLot);
    } else {
      return null;
    }
  }

  Future<void> selectLot(int selectedIndex, BuildContext context) async {
    Lot selectedLot = widget.lots[selectedIndex];

    // Persist the prefered lot
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferedLot', jsonEncode(selectedLot.toJson()));

    // Récupération des détails utilisateur du lot (local) — on enrichit selectedLot
    try {
      final details = await DataBasesUserServices().getLotDetails(
        widget.uid,
        "${selectedLot.residenceData['id']}-${selectedLot.refLot}",
      );

      if (details != null) {
        selectedLot.userLotDetails = details;
        await prefs.setString('lotDetails', jsonEncode(details));
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des détails du lot: $e");
    }

    // ⚠️ NE PAS mettre à jour ColorProvider ici.
    // On prévient le parent et on lui passe le Lot enrichi (il fera la mise à jour couleur et setState).
    widget.onLotSelected?.call(selectedLot);

    // Mise à jour locale du bottomsheet (visuel)
    setState(() {
      preferedLot = selectedLot;
      selectedLotIndexLocal = selectedIndex;
    });

    // Fermer le bottomsheet
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 0),
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              child: ListView.builder(
                itemCount: widget.lots.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 20.0, left: 10),
                    child: RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      title: LotTileView(
                        toShow: true,
                        lot: widget.lots[index],
                        uid: widget.uid,
                      ),
                      value: index,
                      groupValue: selectedLotIndexLocal,
                      onChanged: (int? selectedIndex) {
                        if (selectedIndex != null) {
                          selectLot(selectedIndex, context);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Theme.of(context).primaryColor,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: MyTextStyle.lotName(
                "Fermer",
                Colors.white,
                SizeFont.h3.size,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class LotBottomSheet extends StatefulWidget {
//   final Function()? onRefresh;
//   final Lot? selectedLot;
//   final String uid;
//   final List<Lot> lots;

//   const LotBottomSheet({
//     super.key,
//     this.onRefresh,
//     this.selectedLot,
//     required this.uid,
//     required this.lots,
//   });

//   @override
//   _LotBottomSheetState createState() => _LotBottomSheetState();
// }

// class _LotBottomSheetState extends State<LotBottomSheet> {
//   Lot? preferedLot;
//   int? selectedLotIndexLocal;

//   final LoadPreferedData _loadPreferedData = LoadPreferedData();

//   @override
//   void initState() {
//     super.initState();
//     _initializeSelectedLot();
//   }

//   Future<void> _initializeSelectedLot() async {
//     preferedLot =
//         widget.selectedLot ?? await _loadPreferedData.loadPreferedLot();

//     setState(() {
//       selectedLotIndexLocal = findLotInArray(widget.lots);
//     });
//   }

//   int? findLotInArray(List<Lot> lots) {
//     final currentLot = widget.selectedLot ?? preferedLot;
//     if (currentLot != null) {
//       return lots.indexWhere((element) => element.refLot == currentLot.refLot);
//     } else {
//       return null;
//     }
//   }

//   Future<void> selectLot(int selectedIndex, BuildContext context) async {
//     Lot selectedLot = widget.lots[selectedIndex];

//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('preferedLot', jsonEncode(selectedLot.toJson()));

//     // Récupération des détails utilisateur du lot
//     try {
//       final details = await DataBasesUserServices().getLotDetails(
//         widget.uid,
//         "${selectedLot.residenceData['id']}-${selectedLot.refLot}",
//       );

//       if (details != null) {
//         selectedLot.userLotDetails = details;
//         await prefs.setString('lotDetails', jsonEncode(details));

//         // Mise à jour de la couleur si dispo
//         final colorString = details['colorSelected'];
//         if (colorString != null && context.mounted) {
//           Provider.of<ColorProvider>(context, listen: false)
//               .updateColor(colorString);
//         }
//       }
//     } catch (e) {
//       debugPrint("Erreur lors du chargement des détails du lot: $e");
//     }

//     setState(() {
//       preferedLot = selectedLot;
//       selectedLotIndexLocal = selectedIndex;
//     });

//     widget.onRefresh?.call();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 20, bottom: 0),
//       child: Column(
//         children: [
//           Expanded(
//             child: SizedBox(
//               height: MediaQuery.of(context).size.height * 0.9,
//               child: ListView.builder(
//                 itemCount: widget.lots.length,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: const EdgeInsets.only(right: 20.0, left: 10),
//                     child: RadioListTile<int>(
//                       contentPadding: EdgeInsets.zero,
//                       title: LotTileView(
//                         toShow: true,
//                         lot: widget.lots[index],
//                         uid: widget.uid,
//                       ),
//                       value: index,
//                       groupValue: selectedLotIndexLocal,
//                       onChanged: (int? selectedIndex) {
//                         if (selectedIndex != null) {
//                           selectLot(selectedIndex, context);
//                         }
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           Container(
//             width: double.infinity,
//             color: Theme.of(context).primaryColor,
//             child: TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: MyTextStyle.lotName(
//                 "Fermer",
//                 Colors.white,
//                 SizeFont.h3.size,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
