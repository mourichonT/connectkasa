// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'dart:async';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/post_page_widget/asking_neighbors_widget.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/event_widget.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/annonce_page_widget/annonce_widget.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/post_page_widget/post_widget.dart';
import 'package:flutter/material.dart';

class Homeview extends StatefulWidget {
  String residenceSelected;
  String uid;
  double? upDatescrollController;
  Color colorStatut;
  final Function updatePostsList;
  final Lot preferedLot;
  final bool isCsMember;

  Homeview({
    super.key,
    required this.residenceSelected,
    required this.uid,
    this.upDatescrollController,
    required this.colorStatut,
    required this.updatePostsList,
    required this.preferedLot,
    required this.isCsMember,
  });

  @override
  _HomeviewState createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  late ScrollController _scrollController;
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late Future<List<Post>> _allPostsFuture;
  double scrollPosition = 0.0;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.upDatescrollController ?? 0,
    );
    _scrollController.addListener(_scrollListener);
    _allPostsFuture = _databaseServices.getAllPosts(widget.residenceSelected);
  }

  void _scrollListener() {
    if (mounted) {
      setState(() {
        scrollPosition = _scrollController.offset;
      });
    }
  }

  Future<void> _loadPosts() async {
    final posts = await _databaseServices.getAllPosts(widget.residenceSelected);
    if (mounted) {
      setState(() {
        _allPostsFuture = Future.value(posts);
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadPosts();
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Aucun post n'a été publié pour le moment"),
          );
        } else {
          List<Post> allPosts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.separated(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              itemCount: allPosts.length,
              padding: const EdgeInsets.only(
                  top: 30, bottom: 120, right: 10, left: 10),
              separatorBuilder: (context, index) => const SizedBox(height: 30),
              itemBuilder: (context, index) {
                Post post = allPosts[index];
                return Column(
                  children: [
                    if (post.type == "sinistres" || post.type == "incivilites")
                      PostWidget(
                        widget.preferedLot,
                        post,
                        widget.residenceSelected,
                        widget.uid,
                        scrollPosition,
                        widget.isCsMember,
                        widget.updatePostsList,
                      ),
                    if (post.type == "annonces")
                      AnnonceWidget(
                        lot: widget.preferedLot,
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
                        lot: widget.preferedLot,
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
                        lot: widget.preferedLot,
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
            ),
          );
        }
      },
    );
  }
}
