import 'dart:convert';
import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pages_models/lot.dart';
import 'lot_tile_view.dart';

class LotBottomSheet extends StatefulWidget {
  final Function()? onRefresh;
  final Lot? selectedLot;
  final String UID;

  LotBottomSheet(
      {Key? key, this.onRefresh, this.selectedLot, required this.UID})
      : super(key: key);
  @override
  _LotBottomSheetState createState() => _LotBottomSheetState();
}

class _LotBottomSheetState extends State<LotBottomSheet> {
  //final DatasLots datasLots = DatasLots();
  //late List<Lot> lots;
  final DataBasesServices _databaseServices = DataBasesServices();
  late Future<List<Lot?>> _lotByUser;

  Lot? preferedLot;
  final LoadPreferedData _loadPreferedData = LoadPreferedData();

  Future<void> _loadPreferedLot() async {
    preferedLot = await _loadPreferedData.loadPreferedLot();
    setState(() {});
  }

  int? findLotInArray(List<Lot?> lots) {
    if (preferedLot != null) {
      return lots
          .indexWhere((element) => element?.refLot == preferedLot!.refLot);
    } else
      return null;
  }

  @override
  void initState() {
    super.initState();
    _loadPreferedLot();
    //lots = datasLots.listLot();
    _lotByUser = _databaseServices.getLotByIdUser(widget.UID);
    preferedLot = widget.selectedLot;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 20, bottom: 0),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Lot?>>(
                future: _lotByUser, // Attendre que _lotByUser soit résolu
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
                  List<Lot?> lots =
                      snapshot.data ?? []; // Accéder à la liste de lots
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: ListView.builder(
                      itemCount: lots.length,
                      itemBuilder: (context, index) {
                        return RadioListTile<int>(
                          title: LotTileView(lot: lots[index]!),
                          value: index,
                          groupValue: findLotInArray(lots),
                          onChanged: (int? selectedLotIndex) {
                            // Changement de type ici
                            if (selectedLotIndex != null) {
                              selectLot(selectedLotIndex, context);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              color: Theme.of(context).primaryColor,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    //widget.onRefresh?.call();
                    Navigator.pop(context);
                  });
                },
                child: MyTextStyle.lotName("Fermer", Colors.white),
              ),
            ),
          ],
        ));
  }

// Méthode pour sélectionner un lot
  selectLot(int? selectedLotIndex, context) async {
    if (selectedLotIndex != null) {
      List<Lot?> lots =
          await _lotByUser; // Accéder à la liste lots de la méthode build
      Lot selectedLot = lots[selectedLotIndex]!;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String selectedLotJson = jsonEncode(selectedLot.toJson());
      prefs.setString('preferedLot', selectedLotJson);
      widget.onRefresh?.call();
      // Mettez à jour l'état pour refléter le lot sélectionné
      setState(() {
        preferedLot = selectedLot;
      });
    }
  }
}
