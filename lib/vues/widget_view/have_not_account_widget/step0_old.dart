// import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
// import 'package:connect_kasa/controllers/features/route_controller.dart';
// import 'package:connect_kasa/vues/widget_view/have_not_account_widget/step1.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class Step0 extends StatefulWidget {
//   final String newUser;

//   const Step0({Key? key, required this.newUser}) : super(key: key);

//   @override
//   _Step0State createState() => _Step0State();
// }

// class _Step0State extends State<Step0> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _surnameController = TextEditingController();
//   final TextEditingController? _pseudoController = TextEditingController();

//   // late String nameUser = '';
//   // late String surnameUser = '';
//   // late String pseudoUser = '';

//   @override
//   Widget build(BuildContext context) {
//     double statusBarHeight = MediaQuery.of(context).padding.top;
//     double firstBlockHeight = 10; // Hauteur du premier bloc
//     double width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned(
//             top: statusBarHeight,
//             child: Column(
//               children: [
//                 Container(
//                   height: firstBlockHeight,
//                   width: width * (1 / 5),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             top: statusBarHeight +
//                 firstBlockHeight +
//                 20, // Positionné sous le premier bloc
//             left: 0,
//             right: 0,
//             child: Center(
//               // Centré dans l'écran
//               child: Container(
//                 alignment: Alignment.topCenter,
//                 child: Text(
//                   "Etape 1/5",
//                   style: TextStyle(
//                     color: Colors.black45,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             mainAxisSize: MainAxisSize.max,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: MyTextStyle.lotName(
//                   """Vous venez de vous installer dans une résidence du réseau ConnectKasa. Commençons par renseigner quelques informations. """,
//                   Colors.black54,
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 150,
//                       padding: EdgeInsets.only(right: 20),
//                       child: Text(
//                         "Nom de famille * :",
//                         style: GoogleFonts.robotoCondensed(
//                             fontSize: 16, color: Colors.black87),
//                       ),
//                     ),
//                     Expanded(
//                       child: TextField(
//                         controller: _nameController,
//                         decoration: InputDecoration(
//                             hintText: 'Nom',
//                             hintStyle: GoogleFonts.robotoCondensed(
//                                 color: Colors.black45)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Visibility(
//                   visible: _nameController.text.isNotEmpty,
//                   child: Column(
//                     children: [
//                       Padding(
//                         padding:
//                             EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 150,
//                               padding: EdgeInsets.only(right: 20),
//                               child: Text(
//                                 "Prénom * :",
//                                 style: GoogleFonts.robotoCondensed(
//                                     fontSize: 16, color: Colors.black87),
//                               ),
//                             ),
//                             Expanded(
//                               child: TextField(
//                                 controller: _surnameController,
//                                 decoration: InputDecoration(
//                                     hintText: 'Prénom',
//                                     hintStyle: GoogleFonts.robotoCondensed(
//                                         color: Colors.black45)),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Padding(
//                         padding:
//                             EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 150,
//                               padding: EdgeInsets.only(right: 20),
//                               child: Text(
//                                 "Pseudo :",
//                                 style: GoogleFonts.robotoCondensed(
//                                     fontSize: 16, color: Colors.black45),
//                               ),
//                             ),
//                             Expanded(
//                               child: TextField(
//                                 controller: _pseudoController,
//                                 decoration: InputDecoration(
//                                     hintText: 'Pseudo',
//                                     hintStyle: GoogleFonts.robotoCondensed(
//                                         color: Colors.black45)),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   )),
//             ],
//           ),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Visibility(
//                 visible: _surnameController.text.isNotEmpty,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 30),
//                   child: TextButton(
//                     child: MyTextStyle.lotName(
//                         "Suivant", Theme.of(context).primaryColor),
//                     onPressed: () {
//                       Navigator.of(context).push(RouteController().createRoute(
//                           Step1(
//                               width: width,
//                               statusBarHeight: statusBarHeight,
//                               firstBlockHeight: firstBlockHeight,
//                               newUser: widget.newUser,
//                               nameUser: _nameController.text,
//                               surnameUser: _surnameController.text,
//                               pseudoUser: _pseudoController!.text)));
//                     },
//                   ),
//                 )),
//           )
//         ],
//       ),
//     );
//   }
// }
