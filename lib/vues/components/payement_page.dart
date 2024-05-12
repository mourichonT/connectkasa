import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/transaction_controller.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PayementPage extends StatefulWidget {
  final Post post;
  final String uidFrom;

  const PayementPage({super.key, required this.post, required this.uidFrom});

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
    fees = double.parse(widget.post.price!) * 0.05;
    amount = double.parse(widget.post.price!) * 0.95;
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
                child: MyTextStyle.lotName(
                    "Validation de votre payement", Colors.black87, 20),
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
                        : ImageAnnounced(context, width, height / 3),
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
                            14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: MyTextStyle.annonceDesc(
                            widget.post.description,
                            14,
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
                      16,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    child: MyTextStyle.lotDesc(
                        "Commande:", 14, FontStyle.normal, FontWeight.normal),
                  ),
                  Container(
                    child: MyTextStyle.lotDesc(widget.post.setPrice(amount), 14,
                        FontStyle.normal, FontWeight.normal),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    child: MyTextStyle.lotDesc("Frais de fonctionnement:", 14,
                        FontStyle.normal, FontWeight.normal),
                  ),
                  Container(
                    child: MyTextStyle.lotDesc(widget.post.setPrice(fees), 14,
                        FontStyle.normal, FontWeight.normal),
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
                      child: MyTextStyle.lotDesc(
                          "Total:", 14, FontStyle.normal, FontWeight.w900),
                    ),
                    Container(
                      child: MyTextStyle.lotDesc(
                          widget.post.setPrice(widget.post.price!),
                          14,
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
                  "Récuprération",
                  Colors.black87,
                  16,
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
                          title: MyTextStyle.annonceDesc(option, 14, 2),
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
                      bool transactionReussie =
                          await TransactionController.effectuerTransaction(
                              widget.uidFrom,
                              widget.post.user,
                              amount.toString());

                      if (transactionReussie) {
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
                  ),
                ),
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
