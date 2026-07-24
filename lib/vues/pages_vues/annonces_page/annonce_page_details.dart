import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/profil_page/show_profil_page.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/agent_agency_name_provider.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/core/repositories/user_repository.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/expandable_description.dart';
import 'package:konodal/vues/widget_view/components/fullscreen_image_view.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/pages_vues/chat_page/chat_page.dart';
import 'package:konodal/controllers/pages_controllers/my_nav_bar.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnoncePageDetails extends StatefulWidget {
  final Post post;
  final String uid;
  final String residence;
  final Color colorStatut;
  final double? scrollController;
  final bool returnHomePage;

  const AnnoncePageDetails({
    super.key,
    required this.post,
    required this.uid,
    required this.residence,
    required this.colorStatut,
    this.scrollController,
    required this.returnHomePage,
  });

  @override
  State<StatefulWidget> createState() => AnnoncePageDetailsState();
}

class AnnoncePageDetailsState extends State<AnnoncePageDetails> {
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  late Future<User?> userPost;
  late Future<List<Post>> _allAnnonceFuture;
  final IPostRepository _databaseServices = FirestorePostRepository();
  final IUserRepository _userRepository = FirestoreUserRepository();
  final PageController _galleryController = PageController();
  int _currentImageIndex = 0;

  // Galerie façon Leboncoin : image principale + vignettes dans un seul
  // carrousel plein écran, plutôt qu'une image fixe en haut et les
  // vignettes séparément plus bas dans la page.
  List<String> get _images => [
        if ((widget.post.pathImage ?? '').isNotEmpty) widget.post.pathImage!,
        ...(widget.post.thumbnails ?? []),
      ];

  @override
  void initState() {
    super.initState();
    userPost = _userRepository
        .getUserById(widget.post.user)
        .then((result) => result.when(success: (v) => v, failure: (_) => null));
    _allAnnonceFuture = _databaseServices
        .getAnnonceById(widget.residence, widget.post.user)
        .then((result) => result.when(
            success: (v) => v, failure: (error) => throw error));
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            leading: IconButton(
              onPressed: () async {
                widget.returnHomePage
                    ? Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyNavBar(
                            uid: widget.uid,
                            scrollController: widget.scrollController,
                          ),
                        ),
                      )
                    : Navigator.pop(context);
              },
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child:
                    const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              ),
            ),
            expandedHeight: height / 3,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _images.isEmpty
                  ? imageAnnounced(context, width, height / 3)
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _galleryController,
                          itemCount: _images.length,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageView(
                                    imageUrl: _images[index]),
                              ),
                            ),
                            child:
                                Image.network(_images[index], fit: BoxFit.cover),
                          ),
                        ),
                        if (_images.length > 1)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${_currentImageIndex + 1}/${_images.length}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ShowProfilPage(
                                            uid: widget.post.user,
                                            currentUid: widget.uid,
                                            refLot: widget.residence)),
                                  );

                                  // Refresh après retour de ChatPage
                                  //_fetchAllUsers();
                                },
                                child: profilTile(widget.post.user, 22, 19, 22,
                                    true, Colors.black87, SizeFont.h2.size),
                              ),
                              // ButtonAdd(
                              //   function: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (context) => ChatPage(
                              //           message:
                              //               "Je vous contact au sujet de votre annonce \"${widget.post.title}\", est-ce toujours possible?",
                              //           residence: widget.residence,
                              //           idUserFrom: widget.uid,
                              //           idUserTo: widget.post.user,
                              //         ),
                              //       ),
                              //     );
                              //   },
                              //   color: Theme.of(context).primaryColor,
                              //   icon: Icons.mail,
                              //   text: "Contacter",
                              //   horizontal: 20,
                              //   vertical: 5,
                              //   size: SizeFont.h3.size,
                              // ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              MyTextStyle.lotName(
                                widget.post.title,
                                Colors.black87,
                                SizeFont.h1.size,
                              ),
                              const SizedBox(height: 6),
                              MyTextStyle.lotName(
                                widget.post.setPrice(widget.post.price),
                                Colors.black87,
                                SizeFont.h2.size,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if ((widget.post.subtype ?? '').isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F6F9),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: MyTextStyle.lotDesc(
                                          widget.post.subtype!,
                                          SizeFont.para.size),
                                    ),
                                  const Spacer(),
                                  MyTextStyle.annonceDesc(
                                    MyTextStyle.completDate(
                                        widget.post.creationDate),
                                    SizeFont.para.size,
                                    1,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: ExpandableDescription(
                            text: widget.post.description,
                            style: GoogleFonts.roboto(fontSize: SizeFont.h3.size),
                            collapsedMaxLines: 8,
                          ),
                        ),
                      ],
                    ),
                    // Section masquée entièrement (Divider compris) si le
                    // vendeur n'a aucune AUTRE annonce - avant ce correctif,
                    // le titre "Les autres annonces de ..." restait affiché
                    // même avec une liste vide en dessous.
                    FutureBuilder<List<Post>>(
                      future: _allAnnonceFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        final otherAnnonces = (snapshot.data ?? [])
                            .where((a) => a.id != widget.post.id)
                            .toList();
                        if (otherAnnonces.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            const Divider(),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  child: FutureBuilder<User?>(
                                    future: userPost,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const AppLoader();
                                      } else {
                                        var owner = snapshot.data;
                                        return owner != null
                                            ? Consumer(
                                                builder: (context, ref, _) =>
                                                    MyTextStyle.lotName(
                                                        // Un compte agent/agence n'a jamais
                                                        // de pseudo - displayNameFor peut
                                                        // renvoyer 2 lignes ("\n"), moins
                                                        // naturel dans cette phrase mais
                                                        // reste correct et sans risque de
                                                        // débordement (maxLines/ellipsis).
                                                        "Les autres annonces de ${displayNameFor(ref, owner, (u) => u.pseudo ?? '')}",
                                                        Colors.black87,
                                                        SizeFont.h2.size,
                                                        null,
                                                        TextOverflow.ellipsis,
                                                        2),
                                              )
                                            : const Text('Chargement...');
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 290,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: otherAnnonces.length,
                                    itemBuilder: (context, index) {
                                      Post annonce = otherAnnonces[index];
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          radius: 10,
                                          onTap: () {
                                            Navigator.of(context)
                                                .push(CupertinoPageRoute(
                                              builder: (context) =>
                                                  AnnoncePageDetails(
                                                returnHomePage: false,
                                                post: annonce,
                                                uid: widget.uid,
                                                residence: widget.residence,
                                                colorStatut: widget.colorStatut,
                                                scrollController:
                                                    widget.scrollController,
                                              ),
                                            ));
                                          },
                                          child: Container(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            color: Colors.white,
                                            width: 200,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  // Ajout de ClipRRect pour appliquer le coin arrondi à l'image

                                                  child: annonce.pathImage != ""
                                                      ? SizedBox(
                                                          width: 200,
                                                          height: 130,
                                                          child: Image.network(
                                                            annonce.pathImage!,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )
                                                      : imageAnnounced(
                                                          context, 200, 130),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: MyTextStyle.lotName(
                                                      annonce.title,
                                                      Colors.black87,
                                                      14),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child:
                                                      MyTextStyle.annonceDesc(
                                                          annonce.description,
                                                          SizeFont.h3.size,
                                                          3),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 5),
                                                  child: Row(
                                                    children: [
                                                      MyTextStyle.lotDesc(
                                                        'Prix :',
                                                        SizeFont.h3.size,
                                                        FontStyle.italic,
                                                        FontWeight.w900,
                                                      ),
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                      MyTextStyle.lotName(
                                                        widget.post.setPrice(
                                                            annonce.price),
                                                        Theme.of(context)
                                                            .primaryColor,
                                                        SizeFont.h2.size,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              width: 1,
              color: Colors.black12,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // widget.post.price == ""
              //     ?
              ButtonAdd(
                  function: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          message:
                              "Bonjour, je vous contacte au sujet de votre annonce \"${widget.post.title}\", est-ce toujours possible?",
                          residence: widget.residence,
                          idUserFrom: widget.uid,
                          idUserTo: widget.post.user,
                        ),
                      ),
                    );
                  },
                  color: Theme.of(context).primaryColor,
                  text: "Contacter",
                  horizontal: 20,
                  vertical: 5,
                  size: SizeFont.h2.size)
              // : ButtonAdd(
              //     function: () {
              //       _showBottomSheet(context, widget.post.price!,
              //           widget.uid, widget.post);
              //     },
              //     color: Theme.of(context).primaryColor,
              //     text: "Payer",
              //     horizontal: 20,
              //     vertical: 5,
              //     size: SizeFont.h2.size),
            ],
          ),
        ),
      ),
    );
  }


}
