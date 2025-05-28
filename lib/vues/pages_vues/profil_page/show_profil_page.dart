import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/pages_vues/annonces_page/annonce_page_details.dart';
import 'package:connect_kasa/vues/pages_vues/chat_page/chat_page.dart';
import 'package:connect_kasa/vues/pages_vues/event_page/event_page_details.dart';
import 'package:connect_kasa/vues/pages_vues/post_page/communication_detail.dart';
import 'package:connect_kasa/vues/pages_vues/post_page/post_view.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/image_annonce.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';

class ShowProfilPage extends StatelessWidget {
  final String uid;
  final String refLot;

  const ShowProfilPage({
    super.key,
    required this.uid,
    required this.refLot,
  });

  Future<User?> _loadUser(String uid) async {
    return await DataBasesUserServices.getUserById(uid);
  }

  final bool isSelectedComments = true;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _loadUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text("Erreur de chargement du profil.")),
          );
        }

        final user = snapshot.data!;
        final String name = user.name;
        final String surname = user.surname;
        final String pseudo = user.pseudo ?? "";
        final String bio = user.bio ?? "";
        final String job = user.profession ?? "";
        final bool privateAccount = user.private;
        final String userTo = user.uid;

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
                    ProfilTile(uid, 70, 65, 70, false),
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
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
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
                                        idUserFrom: uid,
                                        idUserTo: userTo,
                                        residence: refLot)),
                              );
                            }),
                      ),
                      if (job.isNotEmpty)
                        Visibility(
                          visible: !privateAccount,
                          child: MyTextStyle.lotDesc(
                            job,
                            SizeFont.h3.size,
                            FontStyle.italic,
                            FontWeight.normal,
                          ),
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
                            tabs: const [
                              Tab(text: "Déclarations"),
                              Tab(text: "Petites Annonces"),
                              Tab(text: "Events"),
                            ],
                          ),
                          ValueListenableBuilder(
                            valueListenable: tabController.animation!,
                            builder: (context, value, _) {
                              final int currentIndex = tabController.index;
                              return Column(
                                children: [
                                  if (currentIndex == 0)
                                    userPostsListByType(uid, refLot, [
                                      "sinistres",
                                      "incivilites",
                                      "communication"
                                    ]),
                                  if (currentIndex == 1)
                                    userPostsListByType(
                                        uid, refLot, ["annonces"]),
                                  if (currentIndex == 2)
                                    userPostsListByType(
                                        uid, refLot, ["events"]),
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

  Widget userPostsListByType(String userId, String refLot, List<String> types) {
    return FutureBuilder<List<Post>>(
      future: DataBasesPostServices.getPostsByUser(refLot, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Aucune publication disponible."));
        }

        final filteredPosts =
            snapshot.data!.where((post) => types.contains(post.type)).toList();

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
                          child: ImageAnnounced(context, 90, 70),
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
  }
}
