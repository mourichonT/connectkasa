// import 'package:connect_kasa/models/pages_models/user.dart';
// import 'package:flutter/material.dart';

// class ParticipantsRow extends StatefulWidget {
//   final List<User?> users;

//   const ParticipantsRow({Key? key, required this.users}) : super(key: key);

//   @override
//   _ParticipantsRowState createState() => _ParticipantsRowState();
// }

// class _ParticipantsRowState extends State<ParticipantsRow> {
//   @override
//   Widget build(BuildContext context) {
//     // return Row(
//     //   crossAxisAlignment: CrossAxisAlignment.end,
//     //   children: widget.users.asMap().entries.map((entry) {
//     //     User? user = entry.value;
//     //     if (user != null) {
//     //       if (user.profilPic != null && user.profilPic != "") {
//     //         return CircleAvatar(
//     //           radius: 12,
//     //           backgroundImage: NetworkImage(user.profilPic!),
//     //         );
//     //       } else {
//     //         String? initName = user.name;
//     //         String? initSurname = user.surname;

//     //         List<String> lettresNom = [];
//     //         List<String> lettresPrenom = [];
//     //         for (int i = 0; i < initName.length; i++) {
//     //           lettresNom.add(initName[i]);
//     //         }
//     //         for (int i = 0; i < initSurname.length; i++) {
//     //           lettresPrenom.add(initSurname[i]);
//     //         }

//     //         String initiale = "${lettresNom.first}${lettresPrenom.first}";

//             return Container(
//               height: 24,
//               width: 24,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Theme.of(context).primaryColor),
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Center(
//                 child: Text(initiale), // Utilisez votre style ici
//               ),
//             );
//           }
//         } else {
//           return Padding(
//             padding: EdgeInsets.only(left: 5),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.circle,
//                   size: 6,
//                 ),
//                 Icon(
//                   Icons.circle,
//                   size: 6,
//                 ),
//                 Icon(
//                   Icons.circle,
//                   size: 6,
//                 ),
//               ],
//             ),
//           );
//         }
//       }).toList(),
//     );
//   }
// }
