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
import 'package:flutter/material.dart';

class AnnoncePageDetails extends StatefulWidget {
  final Post post;
  final String uid;
  final String residence;
  final Color colorStatut;
  final double scrollController;
  final FormatProfilPic formatProfilPic = FormatProfilPic();

  final DataBasesUserServices _databasesUserServices = DataBasesUserServices();

  AnnoncePageDetails(
      {super.key,
      required this.post,
      required this.uid,
      required this.residence,
      required this.colorStatut,
      required this.scrollController});

  @override
  State<StatefulWidget> createState() => AnnoncePageDetailsState();
}

class AnnoncePageDetailsState extends State<AnnoncePageDetails> {
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late Future<User?> userPost =
      widget._databasesUserServices.getUserById(widget.post.user);
  late Future<List<Post>> _allAnnonceFuture =
      _databaseServices.getAnnonceById(widget.residence, widget.uid);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Container(
              child: Stack(children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: widget.post.pathImage != ""
                      ? Image.network(
                          widget.post.pathImage!,
                          fit: BoxFit.cover,
                        )
                      : ImageAnnounced(context, width, 250),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: height / 9,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          IconButton(
                            onPressed: () async {
                              // Naviguer vers une nouvelle instance de Homeview pour recharger l'application
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MyNavBar(
                                          uid: widget.uid,
                                          scrollController:
                                              widget.scrollController)));
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                          ),
                        ]),
                  ),
                ),
                Positioned(
                  top: height / 3,
                  left: 0,
                  right: 0,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 10,
                                      bottom: 10,
                                      left: 10,
                                      right: 10,
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      child: FutureBuilder<User?>(
                                        future: userPost,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          } else {
                                            if (snapshot.hasData &&
                                                snapshot.data != null) {
                                              var user = snapshot.data!;
                                              if (user.profilPic != null &&
                                                  user.profilPic != "") {
                                                return widget.formatProfilPic
                                                    .ProfilePic(17, userPost);
                                              } else {
                                                return widget.formatProfilPic
                                                    .getInitiales(
                                                        34, userPost, 17);
                                              }
                                            } else {
                                              return widget.formatProfilPic
                                                  .getInitiales(
                                                      17, userPost, 3);
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  FutureBuilder<User?>(
                                    future: userPost,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      } else {
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          var user = snapshot.data!;
                                          return MyTextStyle.lotName(
                                            user.pseudo!,
                                            Colors.black87,
                                          );
                                        } else {
                                          return const Text(
                                            'Utilisateur inconnue',
                                            style:
                                                TextStyle(color: Colors.white),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              ButtonAdd(
                                function: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ChatPage(
                                              message:
                                                  "Je vous contact au sujet de votre annonce \"${widget.post.title}\", est-ce toujours possible?",
                                              residence: widget.residence,
                                              idUserFrom: widget.uid,
                                              idUserTo: widget.post.user)));
                                },
                                color: Theme.of(context).primaryColor,
                                icon: Icons.mail,
                                text: "Contacter",
                                horizontal: 10,
                                vertical: 2,
                              ),
                            ],
                          ),
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: MyTextStyle.lotName(
                                  widget.post.title, Colors.black87, 20),
                            ),
                            Container(
                                padding: const EdgeInsets.only(right: 20),
                                child: MyTextStyle.annonceDesc(
                                    MyTextStyle.completDate(
                                        widget.post.timeStamp),
                                    14,
                                    1)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: MyTextStyle.lotDesc(
                              widget.post.subtype ?? 'n/a', 14),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 10),
                              child: MyTextStyle.lotDesc(
                                'Prix :',
                                14,
                                FontWeight.w900,
                              ),
                            ),
                            Container(
                              child: MyTextStyle.lotName(
                                widget.post.setPrice(widget.post.price),
                                Theme.of(context).primaryColor,
                                18,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            child: MyTextStyle.annonceDesc(
                                widget.post.description, 14, 15)),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 20),
                              child: FutureBuilder<User?>(
                                future: userPost,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      var owner = snapshot.data!;
                                      return MyTextStyle.lotName(
                                          "Les annonces de ${owner.pseudo!}",
                                          Colors.black87);
                                    } else {
                                      return Text('Chargement...');
                                    }
                                  }
                                },
                              ),
                            ),
                            FutureBuilder<List<Post>>(
                              future: _allAnnonceFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // Affichez un indicateur de chargement si les données ne sont pas encore disponibles
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  // Gérez les erreurs ici
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  List<Post> allAnnonces = snapshot.data!;
                                  return SizedBox(
                                    height:
                                        400, // Ajustez la hauteur selon vos besoins
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: allAnnonces.length,
                                      itemBuilder: (context, index) {
                                        Post annonce = allAnnonces[index];
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Card(
                                            child: Container(
                                              width:
                                                  200, // Ajustez la largeur selon vos besoins
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  annonce.pathImage != ""
                                                      ? Image.network(
                                                          annonce.pathImage!,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : ImageAnnounced(
                                                          context, 200, 130),
                                                  Text(annonce.title),
                                                  Text(annonce.description),
                                                  // Autres détails de l'annonce
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 100,
                        )
                      ]),
                ),
              ]),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                width: 1, // Adjust the width as needed
                color: Colors.black12, // Specify the color you want
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ButtonAdd(
                  function: () {},
                  color: Theme.of(context).primaryColor,
                  text: widget.post.price == "" ? "Demander" : "Acheter",
                  horizontal: 20,
                  vertical: 10,
                ),
              ],
            ),
          ),
        ));
  }
}
