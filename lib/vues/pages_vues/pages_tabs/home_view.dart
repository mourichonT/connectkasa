// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'dart:async';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/asking_neighbors_widget.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/event_widget.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/annonce_widget.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/post_widget.dart';
import 'package:flutter/material.dart';
import '../../../models/pages_models/post.dart';

class Homeview extends StatefulWidget {
  String residenceSelected;
  String uid;
  double? upDatescrollController;
  Color colorStatut;
  final Function updatePostsList;
  final Lot preferedLot;
  final bool isCsMember;

  Homeview(
      {super.key,
      required this.residenceSelected,
      required this.uid,
      this.upDatescrollController,
      required this.colorStatut,
      required this.updatePostsList,
      required this.preferedLot,
      required this.isCsMember});

  @override
  _HomeviewState createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  late ScrollController _scrollController;
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late Future<List<Post>> _allPostsFuture = Future.value([]);
  final GlobalKey _scrollKey = GlobalKey();
  double scrollPosition = 0.0;
  List<String> itemsCSMembers = [];
  // late bool _isCsMember;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
        initialScrollOffset: widget.upDatescrollController ?? 0);
    _scrollController.addListener(_scrollListener);
    _loadPosts();
  }

  // Chargement des posts depuis la base de données
  Future<void> _loadPosts() async {
    try {
      final posts =
          await _databaseServices.getAllPosts(widget.residenceSelected);
      if (mounted) {
        setState(() {
          _allPostsFuture = Future.value(posts); // Recrée le Future
        });
      }
    } catch (error) {
      print('Erreur de chargement des posts: $error');
    }
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
      future: _allPostsFuture, // Utilisation du Future mis à jour
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("""Aucun post n'a été publié pour le moment """));
        } else {
          List<Post> allPosts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _handleRefresh, // Déclenche la mise à jour des données
            child: SingleChildScrollView(
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
                            widget.isCsMember,
                            widget.updatePostsList,
                          ),
                        if (post.type == "annonces")
                          AnnonceWidget(
                            post: post,
                            uid: widget.uid,
                            residenceSelected: widget.residenceSelected,
                            colorStatut: widget.colorStatut,
                            scrollController: scrollPosition,
                            isCsMember: widget.isCsMember,
                            updatePostsList: widget.updatePostsList,
                          ),
                        if (post.type == "events")
                          EventWidget(
                            post: post,
                            uid: widget.uid,
                            residenceSelected: widget.residenceSelected,
                            colorStatut: widget.colorStatut,
                            scrollController: scrollPosition,
                            isCsMember: widget.isCsMember,
                            updatePostsList: widget.updatePostsList,
                          ),
                        if (post.type == "communication")
                          AskingNeighborsWidget(
                            post: post,
                            uid: widget.uid,
                            residenceSelected: widget.residenceSelected,
                            colorStatut: widget.colorStatut,
                            scrollController: scrollPosition,
                            isCsMember: widget.isCsMember,
                            updatePostsList: widget.updatePostsList,
                          ),
                      ],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 10),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  // Fonction de mise à jour des données lorsqu'on tire vers le bas
  Future<void> _handleRefresh() async {
    await _loadPosts(); // Recharge les posts et met à jour le Future
  }
}
