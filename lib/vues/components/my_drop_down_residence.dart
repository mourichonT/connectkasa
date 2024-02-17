// import 'dart:convert';

// import 'package:connect_kasa/controllers/services/databases_services.dart';
// import 'package:connect_kasa/models/datas/datas_lots.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../controllers/features/my_texts_styles.dart';
// import '../../models/pages_models/lot.dart';

// class MyDropdownResidence extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => _DropdownResidenceState();
// }

// class _DropdownResidenceState extends State<MyDropdownResidence> {

//   final DataBasesServices _databaseServices = DataBasesServices();
//   late Future<List<Lot?>> _lotByUser;

//   final TextEditingController lotController = TextEditingController();
//   Lot? preferedLot;

//   @override
//   void initState() {
//     super.initState();
//     _loadPreferedLot();
//      _lotByUser = _databaseServices.getLotByIduser2(preferedLot!.idProprietaire);

//     preferedLot;
//   }

//   Future<void> _loadPreferedLot() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? lotJson = prefs.getString('preferedLot') ?? '';
//     if (lotJson.isNotEmpty) {
//       Map<String, dynamic> lotMap = json.decode(lotJson);
//       setState(() {
//         preferedLot = Lot.fromJson(lotMap);
//         //print("Je récupère dans SelectLotController ${preferedLot?.name}");
//       });
//     }
//   }

//  // List<Lot> lots = DatasLots().listLot();
//   Lot? dropdownValue;

//   @override
//   Widget build(BuildContext context) {
//     // print("buildcontext : ${preferedLot?.residence?.name}  ${preferedLot?.batiment} ${preferedLot?.lot}");

//     return DropdownMenu<Lot>(
//       // initialSelection: preferedLot,
//       controller: lotController,
//       // requestFocusOnTap is enabled/disabled by platforms when it is null.
//       // On mobile platforms, this is false by default. Setting this to true will
//       // trigger focus request on the text field and virtual keyboard will appear
//       // afterward. On desktop platforms however, this defaults to true.
//       requestFocusOnTap: false,
//       label: const Text('Votre Résidence'),
//       onSelected: (Lot? lot) {
//         setState(() {
//           dropdownValue = lot;
//         });
//       },
//       dropdownMenuEntries: _lotByUser.map<DropdownMenuEntry<Lot>>((Lot lot) {
//         print(
//             "dropdownMenuEntries : ${preferedLot?.residence?.name}  ${preferedLot?.batiment} ${preferedLot?.lot}");
//         String lotName = lot.name.isNotEmpty
//             ? lot.name
//             : "${lot.residence?.name} ${lot.batiment}${lot.lot}";
//         String lotNamePrefered = preferedLot != null &&
//                 preferedLot!.name.isNotEmpty
//             ? preferedLot!.name
//             : "${preferedLot?.residence?.name ?? ''} ${preferedLot?.batiment ?? ''}${preferedLot?.lot ?? ''}";

//         return DropdownMenuEntry<Lot>(
//           value: lot,
//           label: lotName,
//           enabled: lotName != lotNamePrefered,
//         );
//       }).toList(),
//     );
//   }
// }
