import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/post_providers.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/annonces_page/annonce_page_details.dart';
import 'package:konodal/vues/pages_vues/chat_page/chat_page.dart';
import 'package:konodal/vues/pages_vues/event_page/event_page_details.dart';
import 'package:konodal/vues/pages_vues/post_page/communication_detail.dart';
import 'package:konodal/vues/pages_vues/post_page/post_view.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class ShowProfilPage extends ConsumerWidget {
  final String uid;
  final String refLot;
  final String currentUid;

  const ShowProfilPage({
    super.key,
    required this.uid,
    required this.refLot,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(uid));

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: AppLoader()),
      ),
      error: (error, stackTrace) => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Erreur de chargement du profil.")),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text("Erreur de chargement du profil.")),
          );
        }

        final String name = user.name;
        final String surname = user.surname;
        final String pseudo = user.pseudo ?? "";
        final String bio = user.bio ?? "";
        final bool privateAccount = user.private;
        final bool isOwnProfile = currentUid == uid;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: MyTextStyle.lotName(
              pseudo.isNotEmpty ? pseudo : "$name $surname",
              Colors.black87,
              SizeFont.h1.size,
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    profilTile(uid, 70, 65, 70, false),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Column(
                    children: [
                      Visibility(
                        visible: !privateAccount,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MyTextStyle.lotDesc(
                              name,
                              SizeFont.h3.size,
                              FontStyle.normal,
                              FontWeight.bold,
                            ),
                            const SizedBox(width: 5),
                            MyTextStyle.lotDesc(
                              surname,
                              SizeFont.h3.size,
                              FontStyle.normal,
                              FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                      if (pseudo.isNotEmpty)
                        MyTextStyle.lotDesc(
                          "@$pseudo",
                          SizeFont.h3.size,
                          FontStyle.italic,
                          FontWeight.normal,
                        ),
                      // "Ecrire" ne doit rester possible que si ce profil est
                      // toujours membre de CETTE résidence aujourd'hui - un
                      // ancien post reste consultable après le départ de son
                      // auteur (ex-propriétaire détaché, ex-locataire...),
                      // mais il ne doit plus pouvoir être recontacté depuis
                      // ici pour autant. Requête fraîche (pas de cache),
                      // cohérente avec le retrait dénormalisé côté résidence.
                      if (!isOwnProfile)
                        FutureBuilder<List<String>>(
                          future: FirestoreUserRepository()
                              .getNumUsersByResidence(refLot, currentUid)
                              .then((result) => result.when(
                                  success: (v) => v, failure: (_) => <String>[])),
                          builder: (context, snapshot) {
                            final isStillResident =
                                snapshot.data?.contains(uid) ?? false;
                            if (!isStillResident) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: ButtonAdd(
                                  text: "Ecrire",
                                  color: Theme.of(context).primaryColor,
                                  horizontal: 30,
                                  vertical: 5,
                                  size: SizeFont.h3.size,
                                  function: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ChatPage(
                                              idUserFrom: currentUid,
                                              idUserTo: uid,
                                              residence: refLot)),
                                    );
                                  }),
                            );
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              privateAccount
                                  ? Icons.lock_outlined
                                  : Icons.public,
                              size: SizeFont.h3.size,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 10),
                            MyTextStyle.lotDesc(
                              privateAccount
                                  ? "Ce compte est privé"
                                  : "Ce compte est public",
                              SizeFont.h3.size,
                              FontStyle.normal,
                              FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: !privateAccount,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                    child: MyTextStyle.lotDesc(
                      bio,
                      SizeFont.h3.size,
                      FontStyle.normal,
                      FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: MyTextStyle.lotName("Publication dans la residence",
                      Colors.black87, SizeFont.h2.size),
                ),
                DefaultTabController(
                  length: 3,
                  child: Builder(
                    builder: (context) {
                      final TabController tabController =
                          DefaultTabController.of(context);
                      return Column(
                        children: [
                          TabBar(
                            controller: tabController,
                            labelColor: Colors.black87,
                            indicatorColor: Theme.of(context).primaryColor,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            tabs: const [
                              Tab(
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text("Déclarations"))),
                              Tab(
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text("Petites Annonces"))),
                              Tab(
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text("Events"))),
                            ],
                          ),
                          ValueListenableBuilder(
                            valueListenable: tabController.animation!,
                            builder: (context, value, _) {
                              final int currentIndex = tabController.index;
                              return Column(
                                children: [
                                  if (currentIndex == 0)
                                    userPostsListByType(ref, uid, refLot, [
                                      "sinistres",
                                      "incivilites",
                                      "communication"
                                    ]),
                                  if (currentIndex == 1)
                                    userPostsListByType(
                                        ref, uid, refLot, ["annonces"]),
                                  if (currentIndex == 2)
                                    userPostsListByType(
                                        ref, uid, refLot, ["events"]),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget userPostsListByType(
      WidgetRef ref, String userId, String refLot, List<String> types) {
    final postsAsync = ref.watch(
        userPostsByResidenceProvider((residenceId: refLot, userId: userId)));

    return Builder(builder: (context) {
      return postsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 30),
          child: Center(child: AppLoader()),
        ),
        error: (error, stackTrace) =>
            const Center(child: Text("Aucune publication disponible.")),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text("Aucune publication disponible."));
          }

          final filteredPosts =
              posts.where((post) => types.contains(post.type)).toList();

          if (filteredPosts.isEmpty) {
            return const Center(
                child: Text("Aucune publication pour cette catégorie."));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return ListTile(
                  title: MyTextStyle.lotDesc(
                    post.title,
                    SizeFont.h3.size,
                    FontStyle.normal,
                  ),
                  subtitle: Text(post.description),
                  leading: (post.pathImage != null && post.pathImage!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(35.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            width: 90,
                            height: 70,
                            child: Image.network(
                              post.pathImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(35.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            width: 90,
                            height: 70,
                            child: imageAnnounced(context, 90, 70),
                          ),
                        ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        if (post.type == "sinistres" ||
                            post.type == "incivilites") {
                          return PostView(
                            postOrigin: post,
                            residence: refLot,
                            uid: uid,
                            postSelected: post,
                            returnHomePage: false,
                          );
                        } else if (post.type == "communication") {
                          return CommunicationDetails(
                            uid: uid,
                            post: post,
                            residenceId: refLot,
                          );
                        } else if (post.type == "event") {
                          return EventPageDetails(
                            post: post,
                            uid: uid,
                            residence: refLot,
                            colorStatut: Theme.of(context).primaryColor,
                            scrollController: 0,
                            returnHomePage: false,
                          );
                        } else {
                          return AnnoncePageDetails(
                            returnHomePage: false,
                            post: post,
                            uid: uid,
                            residence: refLot,
                            colorStatut: Theme.of(context).primaryColor,
                          );
                        }
                      }),
                    );
                  },
                );
              },
            ),
          );
        },
      );
    });
  }
}
