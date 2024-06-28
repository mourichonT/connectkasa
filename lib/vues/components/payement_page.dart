import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/transaction_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/transaction.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PayementPage extends StatefulWidget {
  final Post post;
  final String uidFrom;
  final String residenceId;

  const PayementPage(
      {super.key,
      required this.post,
      required this.uidFrom,
      required this.residenceId});

  @override
  State<StatefulWidget> createState() => PayementPageState();
}

List<String> options = [
  "Récuperer devant ta porte",
  "Tu peux me livrer devant ma porte"
];

class PayementPageState extends State<PayementPage> {
  late double fees;
  late double amount;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fees = widget.post.price! * 0.05;
    amount = widget.post.price! * 0.95;
    // fees = double.parse(widget.post.price!) * 0.05;
    // amount = double.parse(widget.post.price!) * 0.95;
  }

  String currentOption = options[0];
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return ListView(children: [
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: MyTextStyle.lotName("Validation de votre payement",
                    Colors.black87, SizeFont.h1.size),
              ),
              const Divider(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    width: 120,
                    height: 120,
                    child: widget.post.pathImage != ""
                        ? Image.network(
                            widget.post.pathImage!,
                            fit: BoxFit.cover,
                          )
                        : ImageAnnounced(context, 120, 120),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 10, bottom: 10),
                          child: MyTextStyle.lotName(
                            widget.post.title,
                            Colors.black87,
                            SizeFont.h2.size,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: MyTextStyle.annonceDesc(
                            widget.post.description,
                            SizeFont.h3.size,
                            3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(),
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: MyTextStyle.lotName(
                      "Détails",
                      Colors.black87,
                      SizeFont.h2.size,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    child: MyTextStyle.lotDesc("Commande:", SizeFont.h3.size,
                        FontStyle.normal, FontWeight.normal),
                  ),
                  Container(
                    child: MyTextStyle.lotDesc(widget.post.setPrice(amount),
                        SizeFont.h3.size, FontStyle.normal, FontWeight.normal),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    child: MyTextStyle.lotDesc("Frais de fonctionnement:",
                        SizeFont.h3.size, FontStyle.normal, FontWeight.normal),
                  ),
                  Container(
                    child: MyTextStyle.lotDesc(widget.post.setPrice(fees),
                        SizeFont.h3.size, FontStyle.normal, FontWeight.normal),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      child: MyTextStyle.lotDesc("Total:", SizeFont.h3.size,
                          FontStyle.normal, FontWeight.w900),
                    ),
                    Container(
                      child: MyTextStyle.lotDesc(
                          widget.post.setPrice(widget.post.price!),
                          SizeFont.h3.size,
                          FontStyle.normal,
                          FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Divider(),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: MyTextStyle.lotName(
                  "Récupération",
                  Colors.black87,
                  SizeFont.h2.size,
                ),
              ),
              Column(
                children: options.map((option) {
                  return Center(
                    child: Card(
                      color: Color.fromARGB(13, 255, 255, 255).withOpacity(0.2),
                      shadowColor: Colors.black12,
                      child: Container(
                        width: 300,
                        child: ListTile(
                          title: MyTextStyle.annonceDesc(
                              option, SizeFont.h3.size, 2),
                          leading: Radio(
                            value: option,
                            groupValue: currentOption,
                            onChanged: (value) {
                              setState(() {
                                currentOption = value.toString();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              Center(
                child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: ButtonAdd(
                      function: () async {
                        TransactionModel transaction =
                            await TransactionServices.createdTransac(
                          uidFrom: widget.uidFrom,
                          uidTo: widget.post.user,
                          amount: amount.toString(),
                          fees: fees.toString(),
                          residenceId: widget.residenceId,
                          post: widget.post,
                        );

                        if (transaction.statut == 'en attente') {
                          // Assurez-vous que 'statut' est une propriété de votre TransactionModel indiquant le succès de la transaction
                          showSnackBarFun(context);
                          // Gérer d'autres actions à effectuer en cas de succès de la transaction
                          print("La transaction a été effectuée avec succès.");

                          setState(() {
                            //widget.onRefresh?.call();
                            Navigator.pop(context);
                          });
                        } else {
                          print('La transaction a échoué.');
                          // Gérer d'autres actions à effectuer en cas d'échec de la transaction
                        }
                      },
                      color: Theme.of(context).primaryColor,
                      text: "Valider le paiement",
                      horizontal: 30,
                      vertical: 10,
                      size: SizeFont.h3.size,
                    )),
              ),
            ],
          ),
        ),
      ),
    ]);
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
