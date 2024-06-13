import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/services/transaction_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/transaction.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:flutter/material.dart';

class TransactionTile extends StatefulWidget {
  final TransactionModel transac;
  final String residence;
  final String uid;
  final VoidCallback onAction;

  const TransactionTile(this.transac, this.residence, this.uid, this.onAction,
      {super.key});

  @override
  State<StatefulWidget> createState() => TransactionTileState();
}

class TransactionTileState extends State<TransactionTile> {
  final TransactionServices ts = TransactionServices();
  final DataBasesPostServices postData = DataBasesPostServices();
  late Future<Post> post;

  final DataBasesUserServices databasesUserServices = DataBasesUserServices();
  late Future<User?> userAcheteur;
  late Future<User?> userVendeur;
  late double price;
  String unit = "";

  @override
  void initState() {
    price =
        double.parse(widget.transac.amount) + double.parse(widget.transac.fees);
    price > 1 ? unit = "Kasas" : unit = "Kasa";
    post = postData.getPost(
      widget.residence,
      widget.transac.postId,
    );
    userAcheteur =
        databasesUserServices.getUserById(widget.transac.uidAcheteur);
    userVendeur = databasesUserServices.getUserById(widget.transac.uidVendeur);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.5),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        child: FutureBuilder<Post>(
          future: post,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              var postTransac = snapshot.data;
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5, left: 10),
                          child: MyTextStyle.lotName(
                              postTransac!.title, Colors.black87, 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 5, right: 10),
                        child: MyTextStyle.lotDesc(widget.transac.statut, 13),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Divider(
                      thickness: 1,
                      color: Colors.black12,
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35.0),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            width: 140,
                            height: 140,
                            child: postTransac.pathImage != ""
                                ? Image.network(
                                    postTransac.pathImage!,
                                    fit: BoxFit.cover,
                                  )
                                : ImageAnnounced(context, 140, 140),
                          ),
                        ),
                      ),
                      if (widget.transac.uidAcheteur == widget.uid)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: width / 2,
                              padding: const EdgeInsets.only(top: 5, right: 10),
                              child: MyTextStyle.annonceDesc(
                                "Vous avez reçu le service/produit concerné, veuillez validé votre paiement",
                                13,
                                3,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  child: MyTextStyle.lotDesc("Prix:", 14,
                                      FontStyle.normal, FontWeight.w900),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  child: MyTextStyle.lotDesc(
                                      "${price.toString()} $unit",
                                      14,
                                      FontStyle.normal,
                                      FontWeight.w900),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: widget.transac.statut != "en attente"
                                  ? Container()
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(
                                              left: 10, right: 10),
                                          child: ButtonAdd(
                                            color: Colors.black45,
                                            horizontal: 10,
                                            vertical: 5,
                                            size: 13,
                                            function: () async {
                                              await TransactionServices
                                                  .updatePaymentDate(
                                                      transactionId:
                                                          widget.transac.id,
                                                      isClosed: false);
                                              widget.onAction();
                                            },
                                            text: "Annuler",
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.only(
                                              left: 10, right: 10),
                                          child: ButtonAdd(
                                            color:
                                                Theme.of(context).primaryColor,
                                            horizontal: 10,
                                            vertical: 5,
                                            size: 13,
                                            function: () async {
                                              bool transactionReussie =
                                                  await TransactionServices
                                                      .effectuerTransaction(
                                                idUserEmetteur:
                                                    widget.transac.uidAcheteur,
                                                idUserReceveur:
                                                    widget.transac.uidVendeur,
                                                montant: widget.transac.amount
                                                    .toString(),
                                                fees: widget.transac.fees
                                                    .toString(),
                                              );

                                              if (transactionReussie) {
                                                await TransactionServices
                                                    .updatePaymentDate(
                                                        transactionId:
                                                            widget.transac.id,
                                                        isClosed: true);
                                                widget.onAction();
                                                showSnackBarFun(context);
                                                // Gérer d'autres actions à effectuer en cas de succès de la transaction
                                                print(
                                                    "La transaction a été effectuée avec succès.");
                                              } else {
                                                print(
                                                    'La transaction a échoué.');
                                                // Gérer d'autres actions à effectuer en cas d'échec de la transaction
                                              }
                                            },
                                            text: "Valider",
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        )
                      else if (widget.transac.uidVendeur == widget.uid)
                        Column(
                          children: [
                            Container(
                              width: width / 2,
                              padding: const EdgeInsets.only(top: 5, right: 10),
                              child: MyTextStyle.annonceDesc(
                                "Vous avez recu une demande pour un service",
                                13,
                                3,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
                                    child: ButtonAdd(
                                      color: Colors.black45,
                                      horizontal: 10,
                                      vertical: 5,
                                      size: 13,
                                      function: () {},
                                      text: "Annuler",
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
                                    child: ButtonAdd(
                                      color: Theme.of(context).primaryColor,
                                      horizontal: 10,
                                      vertical: 5,
                                      size: 13,
                                      function: () {},
                                      text: "Relancer",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  showSnackBarFun(context) {
    SnackBar snackBar = SnackBar(
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(
            Icons.thumb_up,
            color: Colors.white,
          ),
          SizedBox(
            width: 20,
          ),
          Expanded(child: Text("La transaction a été effectuée avec succès."))
        ]),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      dismissDirection: DismissDirection.up,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 10,
          right: 10),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
