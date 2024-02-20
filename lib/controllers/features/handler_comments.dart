import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class HandlerComments {
  late TextEditingController _textEditingController;
  late DataBasesServices _databaseServices;
  late Function(bool) _onReply;
  late String _residenceSelected;
  late String _postSelected;
  late String _uid;
  late Future<List<Comment>> _allComments;
  late Future<User?> user;

  HandlerComments(
    TextEditingController textEditingController,
    DataBasesServices databaseServices,
    Function(bool) onReply,
    String residenceSelected,
    String postSelected,
    String uid,
    Future<List<Comment>> allComments,
  ) {
    _textEditingController = textEditingController;
    _databaseServices = databaseServices;
    _onReply = onReply;
    _residenceSelected = residenceSelected;
    _postSelected = postSelected;
    _uid = uid;
    _allComments = allComments;
  }

  void replyToComment(String reply, Comment parentComment, BuildContext context,
      FocusNode focusNode) async {
    // Récupérer l'utilisateur à partir de son ID
    User? user = await _databaseServices.getUserById(parentComment.user);

    // Vérifier si l'utilisateur est récupéré avec succès
    if (user != null) {
      // Focus sur le commentaire en réponse
      FocusScope.of(context).requestFocus(focusNode);

      // Récupérer le texte existant du commentaire
      String existingText = reply;

      // Ajouter une mention du commentaire parent
      String replyText = "@${user.name} ";

      // Concaténer le texte existant avec la mention du commentaire parent et le texte saisi
      String formattedReply = replyText + existingText;

      // Appeler addComment avec commentId pour ajouter la réponse au bon endroit
      addComment(formattedReply, commentId: parentComment.id);

      // Réinitialiser le drapeau isReply après avoir ajouté le commentaire
      _onReply(false);
    } else {
      // Gérer le cas où l'utilisateur n'est pas trouvé
      print("Utilisateur non trouvé");
    }
  }

  void addComment(String commentText, {String? commentId}) async {
    var uuid = Uuid();
    String uniqueId = uuid.v4();

    try {
      // Vérifier si commentId est non nul pour déterminer s'il s'agit d'une réponse à un commentaire
      if (commentId != null) {
        // Ajouter le commentaire comme une réponse au commentaire parent
        await _databaseServices.addComment(
          _residenceSelected,
          _postSelected,
          Comment(
            comment: commentText,
            user: _uid,
            timestamp: Timestamp.now(),
            like: [],
            id: uniqueId,
          ),
          commentParentId: commentId,
        );
      } else {
        // Ajouter le commentaire comme un nouveau commentaire
        await _databaseServices.addComment(
          _residenceSelected,
          _postSelected,
          Comment(
            comment: commentText,
            user: _uid,
            timestamp: Timestamp.now(),
            like: [],
            id: uniqueId,
          ),
        );

        // Actualiser la liste des commentaires
        // Vous devrez probablement mettre à jour _allComments dans la classe SectionComment
        // plutôt que dans cette classe HandlerComments
      }
    } catch (e) {
      print("Error adding comment: $e");
      // Gérer l'erreur
    }
  }
}
