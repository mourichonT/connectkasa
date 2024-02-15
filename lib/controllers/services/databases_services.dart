import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DataBasesServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<Post>> getAllPosts(String doc) async {
    List<Post> posts = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await db.collection("Residence").doc(doc).collection("post").get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        posts.add(Post.fromMap(docSnapshot.data()));
        print(posts);
      }

      print("Successfully completed");
    } catch (e) {
      print("Error completing: $e");
    }

    return posts;
  }

  Future<User?> getUserById(String numUser) async {
    User? user;

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("User")
              .where("numUser", isEqualTo: numUser)
              .get();

      for (var docSnapshot in querySnapshot.docs) {
        print('${docSnapshot.id} => ${docSnapshot.data()}');
      }

      if (querySnapshot.docs.isNotEmpty) {
        // S'il y a des documents correspondants, prenez le premier
        user = User.fromMap(querySnapshot.docs.first.data());
      }

      print("Successfully completed");
    } catch (e) {
      print("Error completing: $e");
    }

    return user;
  }

  Future<User?> getInfoUser(String numUser) async {
    return await getUserById(numUser);
  }

  Future<String?> getImageUrl(String pathImage) async {
    if (pathImage.isNotEmpty) {
      try {
        // Récupérer la référence de l'image depuis Firebase Storage
        final ref = FirebaseStorage.instance.ref().child(pathImage);
        // Obtenir l'URL de téléchargement de l'image
        final imageUrl = await ref.getDownloadURL();
        return imageUrl;
      } catch (e) {
        // Gérer les erreurs, par exemple l'image n'existe pas
        print("Erreur lors de la récupération de l'URL de l'image: $e");
        return null;
      }
    } else {
      return null; // Pas de chemin d'image défini
    }
  }
}
