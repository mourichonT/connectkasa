// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'dart:async';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/vues/widget_view/asking_neighbors_widget.dart';
import 'package:connect_kasa/vues/widget_view/event_widget.dart';
import 'package:connect_kasa/vues/widget_view/annonce_widget.dart';
import 'package:connect_kasa/vues/widget_view/post_widget.dart';
import 'package:flutter/material.dart';
import '../../../models/pages_models/post.dart';

class Homeview extends StatefulWidget {
  String residenceSelected;
  String uid;
  double? upDatescrollController;
  Color colorStatut;
  final Function onPostAdded;

  Homeview({
    super.key,
    required this.residenceSelected,
    required this.uid,
    this.upDatescrollController,
    required this.colorStatut,
    required this.onPostAdded,
  });

  @override
  _HomeviewState createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  late ScrollController _scrollController;
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late Future<List<Post>> _allPostsFuture = Future.value([]);   
  final GlobalKey _scrollKey = GlobalKey();
  double scrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: widget.upDatescrollController ?? 0);
    _scrollController.addListener(_scrollListener);
    
    // Initial loading of posts
    _loadPosts();
  }

  // Chargement des posts depuis la base de données
  Future<void> _loadPosts() async {
    _databaseServices.getAllPosts(widget.residenceSelected).then((posts) {
      if (mounted) {
        setState(() {
          _allPostsFuture = Future.value(posts);  // Mettre à jour _allPostsFuture
        });
      }
    }).catchError((error) {
      print('Erreur de chargement des posts: $error');
    });
  }

  // Appel à _loadPosts lorsque le post est ajouté
  void _handlePostAdded() {
    widget.onPostAdded();  // Appel du callback pour notifier du rafraîchissement
    _loadPosts();  // Rafraîchissement des posts
  }

  void _scrollListener() {
    if (mounted) {
      setState(() {
        scrollPosition = _scrollController.offset;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _allPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Affichage d'un indicateur de chargement
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Gestion des erreurs
          return Text('Erreur: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Aucun post à afficher
          return const Center(child: Text('Aucun post disponible.'));
        } else {
          // Affichage des posts
          List<Post> allPosts = snapshot.data!;
          return SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 35),
              child: ListView.separated(
                key: _scrollKey,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: allPosts.length,
                itemBuilder: (context, index) {
                  Post post = allPosts[index];
                  // Affichage des différents types de posts
                  return Column(
                    children: [
                      if (post.type == "sinistres" || post.type == "incivilites")
                        PostWidget(post, widget.residenceSelected, widget.uid, scrollPosition),
                      if (post.type == "annonces")
                        AnnonceWidget(post: post, uid: widget.uid, residenceSelected: widget.residenceSelected, colorStatut: widget.colorStatut, scrollController: scrollPosition),
                      if (post.type == "events")
                        EventWidget(post: post, uid: widget.uid, residenceSelected: widget.residenceSelected, colorStatut: widget.colorStatut, scrollController: scrollPosition),
                      if (post.type == "communication")
                        AskingNeighborsWidget(post: post, uid: widget.uid, residenceSelected: widget.residenceSelected, colorStatut: widget.colorStatut, scrollController: scrollPosition),
                    ],
                  );
                },
                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10),
              ),
            ),
          );
        }
      },
    );
  }
}
