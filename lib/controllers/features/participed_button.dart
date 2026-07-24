import 'dart:math';

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/post_providers.dart';
import 'package:konodal/core/providers/post_repository_provider.dart';
import 'package:konodal/core/repositories/user_repository.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

/// Participants d'un événement, branchés sur participantsProvider (temps
/// réel) plutôt qu'une copie locale figée à l'ouverture de l'écran - c'est
/// ce qui faisait "perdre" la participation en passant de la carte
/// Homeview (EventWidget) à la page de détail (EventPageDetails), chacune
/// gardant sa propre copie jamais resynchronisée.
class PartipedTile extends ConsumerStatefulWidget {
  final String residenceSelected;
  final Post post;
  final String uid;
  final double space;
  final int number;
  final double sizeFont;

  const PartipedTile({
    super.key,
    required this.residenceSelected,
    required this.post,
    required this.uid,
    required this.space,
    required this.number,
    required this.sizeFont,
  });

  @override
  ConsumerState<PartipedTile> createState() => _PartipedTileState();
}

class _PartipedTileState extends ConsumerState<PartipedTile> {
  static final IUserRepository _userRepository = FirestoreUserRepository();

  // Cache la Future de résolution des avatars, recalculée seulement quand
  // la liste des participants a réellement changé - sans ça, chaque
  // rebuild du widget (ex: recyclage ListView au scroll) créait une
  // nouvelle Future à chaque frame, provoquant un flash de rechargement
  // visible même quand rien n'avait changé côté Firestore.
  List<String>? _cachedParticipants;
  Future<List<User?>>? _usersFuture;

  bool _sameParticipants(List<String>? a, List<String> b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<List<User?>> _usersFor(List<String> participants) {
    if (!_sameParticipants(_cachedParticipants, participants)) {
      _cachedParticipants = participants;
      _usersFuture = _getUsersForParticipants(participants);
    }
    return _usersFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(participantsProvider(
        (residenceId: widget.residenceSelected, postId: widget.post.id)));

    return participantsAsync.when(
      loading: () => const AppLoader(),
      error: (error, _) => Text('Error: $error'),
      data: (participants) {
        final alreadyParticipated = participants.contains(widget.uid);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyTextStyle.lotDesc(
                  widget.post.setParticipant(participants.length),
                  widget.sizeFont,
                  FontStyle.italic,
                  FontWeight.w900,
                ),
                const SizedBox(height: 15),
                buildParticipantsList(participants),
                const SizedBox(height: 15),
              ],
            ),
            alreadyParticipated
                ? ButtonAdd(
                    function: () => _toggleParticipation(participants, true),
                    color: Colors.black38,
                    icon: Icons.cancel_outlined,
                    text: "Se désengager",
                    horizontal: 10,
                    vertical: 2,
                    size: SizeFont.h3.size,
                  )
                : ButtonAdd(
                    function: () => _toggleParticipation(participants, false),
                    color: Theme.of(context).primaryColor,
                    icon: Icons.check,
                    text: "Participer",
                    horizontal: 10,
                    vertical: 2,
                    size: SizeFont.h3.size,
                  ),
          ],
        );
      },
    );
  }

  Widget buildParticipantsList(List<String> participants) {
    return FutureBuilder<List<User?>>(
      future: _usersFor(participants),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoader();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final users = snapshot.data;
        if (users == null || users.isEmpty) {
          return MyTextStyle.annonceDesc('Aucun participant', SizeFont.h3.size, 1);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < min(participants.length, widget.number); i++)
              if (i < users.length && users[i] != null)
                Container(
                  padding: EdgeInsets.all(widget.space),
                  child: profilTile(users[i]!.uid, 12, 11, 12, false),
                ),
          ],
        );
      },
    );
  }

  Future<void> _toggleParticipation(
      List<String> participants, bool alreadyParticipated) async {
    final repository = ref.read(postRepositoryProvider);
    // Pas de setState local : participantsProvider (StreamProvider) capte
    // l'écriture Firestore et republie automatiquement la nouvelle liste à
    // tous les écrans qui l'observent (Homeview ET détail).
    if (!alreadyParticipated) {
      await repository
          .updatePostParticipants(widget.residenceSelected, widget.post.id, widget.uid)
          .then((result) => result.when(success: (_) {}, failure: (error) => throw error));
    } else {
      await repository
          .removePostParticipants(widget.residenceSelected, widget.post.id, widget.uid)
          .then((result) => result.when(success: (_) {}, failure: (error) => throw error));
    }
  }

  Future<List<User?>> _getUsersForParticipants(List<String> participantIds) async {
    List<User?> users = [];
    for (String id in participantIds) {
      User? user = await _userRepository
          .getUserById(id)
          .then((result) => result.when(success: (v) => v, failure: (_) => null));
      users.add(user);
    }
    return users;
  }
}
