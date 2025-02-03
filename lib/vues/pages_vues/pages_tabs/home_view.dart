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

  Homeview(
      {super.key,
      required this.residenceSelected,
      required this.uid,
      this.upDatescrollController,
      required this.colorStatut});

  @override
  _HomeviewState createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  late ScrollController _scrollController = ScrollController();
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late Future<List<Post>> _allPostsFuture;
  //late Color colorStatut = Theme.of(context).primaryColor;
  final GlobalKey _scrollKey = GlobalKey();
  double scrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
        initialScrollOffset: widget.upDatescrollController ?? 00);
    _scrollController.addListener(_scrollListener);
    _allPostsFuture = _databaseServices.getAllPosts(widget.residenceSelected);
  }

  void _scrollListener() {
    setState(() {
      scrollPosition = _scrollController.offset;
    });
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
                  return Column(
                    children: [
                      if (post.type == "sinistres" ||
                          post.type == "incivilites")
                        PostWidget(
                          post,
                          widget.residenceSelected,
                          widget.uid,
                          scrollPosition,
                        ),
                      if (post.type == "annonces")
                        AnnonceWidget(
                          post: post,
                          uid: widget.uid,
                          residenceSelected: widget.residenceSelected,
                          colorStatut: widget.colorStatut,
                          scrollController: scrollPosition,
                        ),
                      if (post.type == "events")
                        EventWidget(
                          post: post,
                          uid: widget.uid,
                          residenceSelected: widget.residenceSelected,
                          colorStatut: widget.colorStatut,
                          scrollController: scrollPosition,
                        ),
                      if (post.type == "communication")
                        AskingNeighborsWidget(
                          post: post,
                          uid: widget.uid,
                          residenceSelected: widget.residenceSelected,
                          colorStatut: widget.colorStatut,
                          scrollController: scrollPosition,
                        )
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
