// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/vues/widget_view/post_widget.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/post.dart';
import '../widget_view/annonce_widget.dart';

class Homeview extends StatefulWidget {
  String residenceSelected;
  String uid;

  Homeview({super.key, required this.residenceSelected, required this.uid});

  @override
  _HomeviewState createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late Future<List<Post>> _allPostsFuture;

  @override
  void initState() {
    super.initState();
    _allPostsFuture = _databaseServices.getAllPosts(widget.residenceSelected);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _allPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Affichez un indicateur de chargement si les données ne sont pas encore disponibles
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          // Gérez les erreurs ici
          return Text('Error: ${snapshot.error}');
        } else {
          // Les données sont prêtes, vous pouvez maintenant utiliser snapshot.data
          List<Post> allPosts = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 35),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: allPosts.length,
                itemBuilder: (context, index) {
                  Post post = allPosts[index];
                  return Column(
                    children: [
                      if (post.type == "sinistres" ||
                          post.type == "incivilites")
                        PostWidget(post, widget.residenceSelected, widget.uid),
                      if (post.type == "Annonces") AnnonceWidget(post),
                    ],
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
