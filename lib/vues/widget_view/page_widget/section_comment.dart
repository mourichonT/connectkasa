// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/providers/comment_providers.dart';
import 'package:konodal/core/providers/comment_repository_provider.dart';
import 'package:konodal/models/pages_models/comment.dart';
import 'package:konodal/vues/widget_view/components/comment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

/// Affiche et permet d'ajouter des commentaires/réponses sur un post.
/// Les commentaires sont un flux temps réel (commentsStreamProvider) :
/// contrairement à l'ancienne version (Future chargé une fois, refetché
/// manuellement après chaque ajout), un nouveau commentaire/une nouvelle
/// réponse apparaît dès son écriture en base, y compris si elle vient
/// d'un autre utilisateur pendant que ce panneau est ouvert.
class SectionComment extends ConsumerStatefulWidget {
  final String residenceSelected;
  final String postSelected;
  final String uid;

  const SectionComment({
    super.key,
    required this.residenceSelected,
    required this.postSelected,
    required this.uid,
  });

  @override
  _SectionCommentState createState() => _SectionCommentState();
}

class _SectionCommentState extends ConsumerState<SectionComment>
    with WidgetsBindingObserver {
  double keyBoardHeight = 0;
  FocusNode inputFocusNode = FocusNode();
  bool focused = false;
  TextEditingController _textEditingController = TextEditingController();
  bool isReply = false;
  String commentId = "";
  String initialComment = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final mediaQuery = MediaQuery.of(context);
    setState(() {
      keyBoardHeight = mediaQuery.viewInsets.bottom != 0.0
          ? mediaQuery.viewInsets.bottom - 20.0
          : 0.0;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsStreamProvider((
      residenceId: widget.residenceSelected,
      postId: widget.postSelected,
    )));

    return commentsAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, _) => Text('Error: $error'),
      data: (allComments) {
        return Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: allComments.length,
                itemBuilder: (context, index) {
                  final comment = allComments[index];
                  return Column(
                    children: [
                      CommentTile(
                        widget.residenceSelected,
                        comment,
                        widget.uid,
                        widget.postSelected,
                        inputFocusNode,
                        _textEditingController,
                        key: ValueKey(comment.id),
                        onReply: (value) {
                          setState(() {
                            isReply = value;
                          });
                        },
                        getCommentId: (value) {
                          setState(() {
                            commentId = value;
                          });
                        },
                        getUsertoreply: (value) {
                          setState(() {
                            _textEditingController = value;
                          });
                        },
                        getInitialComment: (value) {
                          setState(() {
                            initialComment = value!;
                          });
                        },
                      )
                    ],
                  );
                },
              ),
            ),
            _buildCommentInput(context),
          ],
        );
      },
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Positioned(
      bottom: keyBoardHeight,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(inputFocusNode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: IgnorePointer(
                  child: TextFormField(
                    enableInteractiveSelection: true,
                    keyboardType: TextInputType.multiline,
                    maxLines: 6,
                    minLines: 1,
                    controller: _textEditingController,
                    focusNode: inputFocusNode,
                    decoration: const InputDecoration(
                      hintMaxLines: 15,
                      hintText: 'Ajouter un commentaire...',
                    ),
                  ),
                ),
              ),
              IconButton(
                color: Theme.of(context).colorScheme.primary,
                icon: const Icon(Icons.send_rounded),
                onPressed: () {
                  if (isReply == true) {
                    if (_textEditingController.text.isNotEmpty) {
                      _addComment(
                        _textEditingController,
                        isReply,
                        commentId: commentId,
                        initialComment: initialComment,
                      );
                      _textEditingController.clear();
                    }
                  } else {
                    if (isReply == false &&
                        _textEditingController.text.isNotEmpty) {
                      _addComment(
                        _textEditingController,
                        isReply,
                        commentId: commentId,
                        initialComment: initialComment,
                      );
                      _textEditingController.clear();
                    }
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  void _addComment(TextEditingController textEditingController, bool isReply,
      {String? commentId, required String? initialComment}) async {
    final commentRepository = ref.read(commentRepositoryProvider);
    var uuid = const Uuid();
    String uniqueId = uuid.v4();
    if (isReply == true) {
      final String formattedComment =
          _formatComment(textEditingController.text);

      final result = await commentRepository.addComment(
          widget.residenceSelected,
          widget.postSelected,
          Comment(
            comment: capitalizeFirstLetter(formattedComment),
            user: widget.uid,
            timestamp: Timestamp.now(),
            like: [],
            id: uniqueId,
            originalCommment: !isReply,
            initialComment: initialComment,
          ),
          commentId: commentId,
          initialComment: initialComment);

      if (!result.isSuccess) {
        appLog("Error adding reply: ${result.errorOrNull}");
      }
    } else {
      final result = await commentRepository.addComment(
        widget.residenceSelected,
        widget.postSelected,
        Comment(
          comment: capitalizeFirstLetter(_textEditingController.text),
          user: widget.uid,
          timestamp: Timestamp.now(),
          like: [],
          id: uniqueId,
          originalCommment: !isReply,
        ),
      );
      if (!result.isSuccess) {
        appLog("Error adding comment: ${result.errorOrNull}");
      }
    }
  }

  String _formatComment(String comment) {
    final RegExp regex = RegExp(r"@([A-Z][a-z]+(?:[A-Z][a-z]+)*)\s+(.*)");
    final Iterable<Match> matches = regex.allMatches(comment);
    String formattedComment = "";

    for (final Match match in matches) {
      final String name = match.group(1)!;
      final String restOfThePhrase = match.group(2)!;
      final String formattedName =
          name.replaceAllMapped(RegExp(r"(?=[A-Z])"), (match) => " ");

      formattedComment += "$formattedName $restOfThePhrase";
    }

    return formattedComment.isNotEmpty ? formattedComment : comment;
  }
}
