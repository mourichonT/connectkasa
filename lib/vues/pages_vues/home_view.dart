import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/models/datas/datas_posts.dart';
import 'package:connect_kasa/vues/components/post_widget.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/post.dart';
import '../components/annonce_widget.dart';

class Homeview extends StatefulWidget {
  @override
  _HomeviewState createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  final DataBasesServices _databaseServices = DataBasesServices();
  late Future<List<Post>> _allPostsFuture;

  @override
  void initState() {
    super.initState();
    _allPostsFuture = _databaseServices.getAllPosts("carreSalambo");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _allPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Affichez un indicateur de chargement si les données ne sont pas encore disponibles
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Gérez les erreurs ici
          return Text('Error: ${snapshot.error}');
        } else {
          // Les données sont prêtes, vous pouvez maintenant utiliser snapshot.data
          List<Post> allPosts = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: ListView.separated(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemCount: allPosts.length,
                itemBuilder: (context, index) {
                  Post post = allPosts[index];
                  return Column(
                    children: [
                      if (post.type == "Sinistre" || post.type == "Incivilité")
                        PostWidget(post),
                      if (post.type == "Annonces") AnnonceWidget(post),
                    ],
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
