import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:connect_kasa/vues/pages_vues/annonce_page_details.dart';
import 'package:connect_kasa/vues/pages_vues/communication_detail.dart';
import 'package:connect_kasa/vues/pages_vues/modify_annonceform.dart';
import 'package:connect_kasa/vues/pages_vues/modify_asking_neighbors_form.dart';
import 'package:connect_kasa/vues/pages_vues/modify_postform.dart';
import 'package:connect_kasa/vues/pages_vues/post_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SinistreTile extends StatefulWidget {
  late Post post;
  final String uid;
  final String residenceId;
  final bool canModify;
  final Color colorStatut;
  final Function()? updatePostsList;

  SinistreTile(this.post, this.residenceId, this.uid, this.canModify,
      this.colorStatut, this.updatePostsList, {super.key});

  @override
  State<StatefulWidget> createState() => SinistreTileState();
}

class SinistreTileState extends State<SinistreTile> {
  final StorageServices _storageServices = StorageServices();
  DataBasesPostServices dbService = DataBasesPostServices();
  final DataBasesUserServices databasesUserServices = DataBasesUserServices();
  List<List<String>> typeList = TypeList().typeDeclaration();
  String url = "";
  Post? _signalement;

  int postCount = 0;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _fetchPost();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _fetchPost() async {
    Post signalement =
        await dbService.getPost(widget.residenceId, widget.post.id);
    if (_isMounted) {
      setState(() {
        _signalement = signalement;
      });
    }
  }

  String getType(Post post) {
    for (var type in typeList) {
      var typeName = type[0];
      var typeValue = type[1];
      if (widget.post.type == typeValue) {
        return typeName;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FutureBuilder<Post?>(
                      future: dbService.getUpdatePost(
                          widget.residenceId, widget.post.id),
                      builder: (BuildContext context,
                          AsyncSnapshot<Post?> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          final postUpdated = snapshot.data;
                          if (postUpdated != null) {
                            return PopScope(
                              onPopInvoked: (didPop) async {
                                Post? postChanges =
                                    await dbService.getUpdatePost(
                                        widget.residenceId, widget.post.id);

                                if (postChanges != null && mounted) {
                                  setState(() {
                                    widget.post = postChanges;
                                  });
                                }
                              },
                              child: Builder(builder: (context) {
                                print("postType : ${widget.post.type}" );
                                if (widget.post.type == "sinistres" ||
                                    widget.post.type == "incivilites") {
                                  return PostView(
                                    postOrigin: widget.post,
                                    residence: widget.residenceId,
                                    uid: widget.uid,
                                    postSelected: widget.post,
                                    returnHomePage: false,
                                  );
                                } else if (widget.post.type ==
                                    "communication") {
                                  return CommunicationDetails(
                                      uid: widget.uid, post: widget.post);
                                } else {
                                  return AnnoncePageDetails(
                                    returnHomePage: false,
                                    post: widget.post,
                                    uid: widget.uid,
                                    residence: widget.residenceId,
                                    colorStatut: widget.colorStatut,
                                  );
                                }
                              }),
                            );
                          } else {
                            //return const Text('No data');
                            if (widget.post.type == "sinistres" ||
                                    widget.post.type == "incivilites") {
                                  return PostView(
                                    postOrigin: widget.post,
                                    residence: widget.residenceId,
                                    uid: widget.uid,
                                    postSelected: widget.post,
                                    returnHomePage: false,
                                  );
                                } else if (widget.post.type ==
                                    "communication") {
                                  return CommunicationDetails(
                                      uid: widget.uid, post: widget.post);
                                } else {
                                  return AnnoncePageDetails(
                                    returnHomePage: false,
                                    post: widget.post,
                                    uid: widget.uid,
                                    residence: widget.residenceId,
                                    colorStatut: widget.colorStatut,
                                  );
                                }
                          }
                        }
                      },
                    )),
          );
        },
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 10),
              width: MediaQuery.of(context).size.width * 0.95,
              child: _signalement == null
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        if (_signalement!.pathImage != "" &&
                            _signalement!.pathImage != null &&
                            _signalement!.pathImage!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              width: 120,
                              height: 120,
                              child: Image.network(
                                _signalement!.pathImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              width: 120,
                              height: 120,
                              child: ImageAnnounced(context, 120, 120),
                            ),
                          ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.post.type != "annonces")
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    MyTextStyle.postDesc(getType(widget.post),
                                        SizeFont.para.size, Colors.black87),
                                    if (!_signalement!.hideUser)
                                      if (!widget.canModify)
                                        FutureBuilder<User?>(
                                            future: databasesUserServices
                                                .getUserById(
                                                    _signalement!.user),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              } else {
                                                var user = snapshot.data;
                                                if (user != null) {
                                                  return widget.post.user ==
                                                          widget.uid
                                                      ? MyTextStyle.annonceDesc(
                                                          "Vous",
                                                          SizeFont.para.size,
                                                          1)
                                                      : MyTextStyle.annonceDesc(
                                                          user.pseudo ?? "",
                                                          SizeFont.para.size,
                                                          1);
                                                } else {
                                                  return Container();
                                                }
                                              }
                                            }),
                                  ],
                                ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyTextStyle.lotName(_signalement!.title,
                                      Colors.black87, SizeFont.h3.size),
                                  MyTextStyle.annonceDesc(
                                      _signalement!.description,
                                      SizeFont.para.size,
                                      2),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      MyTextStyle.commentDate(
                                          _signalement!.timeStamp),
                                      MyTextStyle.lotDesc(_signalement!.statu!,
                                          SizeFont.para.size),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.canModify)
                          Container(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (widget.post.type == "communication") {
                                        Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                                builder: (context) =>
                                                    ModifyAskingNeighborsForm(
                                                      uid: widget.uid,
                                                      residence:
                                                          widget.residenceId,
                                                      post: _signalement!,
                                                    )));
                                      }

                                      if (widget.post.type == "sinistres" ||
                                          widget.post.type == "incivilites") {
                                        Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                                builder: (context) =>
                                                    ModifyPostForm(
                                                      uid: widget.uid,
                                                      residence:
                                                          widget.residenceId,
                                                      post: _signalement!,
                                                    )));
                                      }
                                      if (widget.post.type == "annonces") {
                                        Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                                builder: (context) =>
                                                    ModifyAnnonceForm(
                                                      uid: widget.uid,
                                                      residence:
                                                          widget.residenceId,
                                                      post: _signalement!,
                                                    )));
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 20,
                                    )),
                                IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      showAlertDialog(
                                          context, _signalement!.title);
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 20,
                                    )),
                              ],
                            ),
                          )
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void updateUrl(String updatedUrl) {
    url = updatedUrl;
  }

  showAlertDialog(BuildContext context, String title) async {
    Widget cancelButton = TextButton(
      child: MyTextStyle.lotName("Annuler ", Colors.black87, SizeFont.h3.size),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child:
          MyTextStyle.lotName("Supprimer ", Colors.black87, SizeFont.h3.size),
      onPressed: () async {
        if (widget.updatePostsList != null) {
          _onDeletePost();
        }
      },
    );

    AlertDialog alert = AlertDialog(
      title: MyTextStyle.lotName(
          "Confirmation ", Colors.black87, SizeFont.h1.size),
      content: MyTextStyle.annonceDesc(
          "Etes-vous sûr de vouloir supprimer '$title' ", SizeFont.h3.size, 3),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _onDeletePost() async {
    // final DataBasesPostServices _databaseServices = DataBasesPostServices();
    await dbService.removePost(widget.residenceId, widget.post.id);
    await _storageServices.removeFileFromUrl(widget.post.pathImage!);
    // await _databaseServices.getAllPostsToModify(widget.residenceId);
    widget.updatePostsList!();
    Navigator.pop(context);
  }
}
