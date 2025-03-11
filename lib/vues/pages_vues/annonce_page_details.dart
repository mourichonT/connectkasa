import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/components/payement_page.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:connect_kasa/vues/pages_vues/chat_page.dart';
import 'package:connect_kasa/vues/pages_vues/my_nav_bar.dart';

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
  late Future<User?> userCurrent;
  late Future<List<Post>> _allAnnonceFuture;
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  final DataBasesUserServices _databasesUserServices = DataBasesUserServices();

  @override
  void initState() {
    super.initState();
    userCurrent = _databasesUserServices.getUserById(widget.uid);
    userPost = _databasesUserServices.getUserById(widget.post.user);
    _allAnnonceFuture =
        _databaseServices.getAnnonceById(widget.residence, widget.post.user);
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
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
            ),
            expandedHeight: height / 3,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.post.pathImage != ""
                  ? Image.network(
                      widget.post.pathImage!,
                      fit: BoxFit.cover,
                    )
                  : ImageAnnounced(context, width, height / 3),
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
                              ProfilTile(widget.post.user, 22, 19, 22, true,
                                  Colors.black87, SizeFont.h2.size),
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
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: 30,
                                child: MyTextStyle.lotName(
                                  widget.post.title,
                                  Colors.black87,
                                  SizeFont.h1.size,
                                ),
                              ),
                              MyTextStyle.annonceDesc(
                                MyTextStyle.completDate(widget.post.timeStamp),
                                SizeFont.h3.size,
                                1,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: MyTextStyle.lotDesc(
                              widget.post.subtype ?? 'n/a', SizeFont.h3.size),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
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
                                    widget.post.setPrice(widget.post.price),
                                    Theme.of(context).primaryColor,
                                    SizeFont.h2.size,
                                  ),
                                ],
                              ),
                              // Row(
                              //   children: [
                              //     MyTextStyle.lotDesc(
                              //       'Votre solde :',
                              //       SizeFont.h3.size,
                              //       //FontWeight.w300,
                              //     ),
                              //     SizedBox(
                              //       width: 5,
                              //     ),
                              //     FutureBuilder<User?>(
                              //       future: userCurrent,
                              //       builder: (context, snapshot) {
                              //         if (snapshot.connectionState ==
                              //             ConnectionState.waiting) {
                              //           return CircularProgressIndicator();
                              //         } else {
                              //           var user = snapshot.data;
                              //           if (user != null) {
                              //             return MyTextStyle.lotDesc(
                              //               user.setSolde(user.solde),
                              //               SizeFont.h3.size,
                              //             );
                              //           } else {
                              //             return Text('Utilisateur inconnu');
                              //           }
                              //         }
                              //       },
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: MyTextStyle.annonceDesc(
                            widget.post.description,
                            SizeFont.h3.size,
                            15,
                          ),
                        ),
                      ],
                    ),
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
                                return const CircularProgressIndicator();
                              } else {
                                var owner = snapshot.data;
                                return owner != null
                                    ? MyTextStyle.lotName(
                                        "Les autres annonces de ${owner.pseudo!}",
                                        Colors.black87,
                                        SizeFont.h2.size)
                                    : const Text('Chargement...');
                              }
                            },
                          ),
                        ),
                        FutureBuilder<List<Post>>(
                          future: _allAnnonceFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              List<Post> allAnnonces = snapshot.data ?? [];
                              return SizedBox(
                                height: 290,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: allAnnonces.length,
                                  itemBuilder: (context, index) {
                                    Post annonce = allAnnonces[index];
                                    if (annonce.id != widget.post.id) {
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
                                            padding: const EdgeInsets.only(left: 10),
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
                                                      : ImageAnnounced(
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
                                    } else {
                                      // Retourner un widget vide si c'est l'annonce principale
                                      return const SizedBox.shrink();
                                    }
                                  },
                                ),
                              );
                            }
                          },
                        ),
                      ],
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
          padding: const EdgeInsets.all(10),
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
                                  "Bonjour, je souhaiterais réservé \"${widget.post.title}\", est-ce toujours possible?",
                              residence: widget.residence,
                              idUserFrom: widget.uid,
                              idUserTo: widget.post.user,
                            ),
                          ),
                        );
                      },
                      color: Theme.of(context).primaryColor,
                      text: "Réservé",
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

  void _showBottomSheet(
      BuildContext context, int price, String uidFrom, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Pour rendre le contenu scrollable
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 3 / 4, // Définir la fraction de la hauteur de l'écran
          child: Container(
            // Contenu du BottomSheet
            child: PayementPage(
              post: post,
              uidFrom: uidFrom,
              residenceId: widget.residence,
            ),
          ),
        );
      },
    );
  }
}
