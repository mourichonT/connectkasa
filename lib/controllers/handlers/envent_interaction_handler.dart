// // Classe utilitaire pour gérer les interactions liées à la participation à un événement
// import 'package:connect_kasa/controllers/services/databases_post_services.dart';
// import 'package:connect_kasa/controllers/services/databases_user_services.dart';
// import 'package:connect_kasa/models/pages_models/post.dart';
// import 'package:connect_kasa/models/pages_models/user.dart';

// class EventInteractionUtil {
//   static void participedUser(
//     Post post,
//     String residenceSelected,
//     String uid,
//     bool alreadyParticipated,
//     Function(bool) setStateCallback,
//     Function(List<User?>) setParticipantsCallback,
//     int userParticipatedCount,
//   ) async {
//     if (!alreadyParticipated) {
//       await DataBasesPostServices().updatePostParticipants(
//         residenceSelected,
//         post.id,
//         uid,
//       );
//       setStateCallback(true);
//       setParticipantsCallback(
//           await getUsersForParticipants(post.participants!));
//     } else {
//       await DataBasesPostServices().removePostParticipants(
//         residenceSelected,
//         post.id,
//         uid,
//       );
//       setStateCallback(false);
//       setParticipantsCallback(
//           await getUsersForParticipants(post.participants!));
//     }
//   }

//   static Future<List<User?>> getUsersForParticipants(
//       List<String> participantIds) async {
//     List<User?> users = [];
//     for (String id in participantIds) {
//       User? user = await DataBasesUserServices().getUserById(id);
//       users.add(user);
//     }
//     return users;
//   }
// }
