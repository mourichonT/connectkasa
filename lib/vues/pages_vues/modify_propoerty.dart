import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/statut_list.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/colo_circle.dart';
import 'package:connect_kasa/vues/widget_view/color_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ModifyProperty extends StatefulWidget {
  final Lot lot;
  final String uid;

  const ModifyProperty({
    Key? key,
    required this.lot,
    required this.uid,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ModifyPropertyState();
}

class ModifyPropertyState extends State<ModifyProperty> {
  DataBasesLotServices lotServices = DataBasesLotServices();

  TextEditingController name = TextEditingController();
  String? selectedStatut;

  FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    nameFocusNode.addListener(() => setState(() {}));
    _loadProperty();
  }

  @override
  void dispose() {
    super.dispose();
    nameFocusNode.dispose();
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          widget.lot.nameProp != null && widget.lot.nameProp != ""
              ? widget.lot.nameProp!
              : "${widget.lot.residenceData['name']} ${widget.lot.lot}",
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => ColorView(
                              residenceId: widget.lot.residenceId,
                              refLot: widget.lot.refLot,
                            )));
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 25, bottom: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .primaryColor, // Utilisation de la couleur primaire du thème
                          radius: 10, // Rayon du cercle
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape
                                  .circle, // Définir la forme comme un cercle
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: Text(
                            "Couleur du bien",
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeFont.h3.size),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_right_outlined,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
            Divider(),
            _buildModifyTextField('Nom', name, nameFocusNode),
            _buildReadOnlyTextField('Type', widget.lot.typeLot),
            _buildReadOnlyTextField(
                'Residence', widget.lot.residenceData['name']),
            _buildReadOnlyTextField('Référence Lot', widget.lot.refLot),
            _buildReadOnlyTextField('Bâtiment', widget.lot.batiment),
            _buildReadOnlyTextField('Référence Lot', widget.lot.refLot),
            _buildReadOnlyTextField('Lot', widget.lot.lot),
            _buildReadOnlyTextField('Adresse',
                "${widget.lot.residenceData["numero"]} ${widget.lot.residenceData["voie"]} ${widget.lot.residenceData["street"]}"),
            _buildReadOnlyTextField(
                'Code Postal', widget.lot.residenceData["zipCode"]),
            _buildReadOnlyTextField('Ville', widget.lot.residenceData["city"]),
            _buildDropDownMenu(width, 'Statut'),
            if (!widget.lot.idLocataire!.contains(widget.uid))
              Visibility(
                visible: selectedStatut == "Location longue durée" ||
                    selectedStatut == "Location courte durée",
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15, bottom: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Ma gérance locative",
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                  fontSize: SizeFont.h3.size),
                            ),
                            Icon(
                              Icons.arrow_right_outlined,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(),
                  ],
                ),
              ),
            SizedBox(
              height: 80,
            )
          ],
        ),
      ),
      bottomSheet: Container(
        height: 50,
        //alignment: Alignment.bottomCenter,
        width: MediaQuery.of(context).size.width,
        color: Colors.transparent,
        child: Center(
          child: ButtonAdd(
              function: () {},
              text: "Supprimer",
              color: Colors.black26,
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size),
        ),
      ),
    );
  }

  Widget _buildDropDownMenu(double width, String label) {
    List<String> statuts = StatutList.statutList();
    bool isEnabled = !widget.lot.idLocataire!.contains(widget.uid);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w400,
              fontSize: SizeFont.h3.size),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
            ),
          ),
        ),
        value: selectedStatut,
        items: statuts.map((statut) {
          return DropdownMenuItem(
            value: statut, // Assurez-vous que chaque valeur est unique
            child: Text(
              statut,
              style: TextStyle(
                  color: isEnabled ? Colors.black87 : Colors.black54,
                  fontWeight: FontWeight.w400,
                  fontSize: SizeFont.h3.size),
            ),
          );
        }).toList(),
        onChanged: isEnabled
            ? (newValue) {
                setState(() {
                  selectedStatut = newValue as String?;
                  widget.lot.type = selectedStatut!;
                });
              }
            : null,
        isExpanded: true,
        style: TextStyle(
            color: isEnabled ? Colors.black54 : Colors.black87,
            fontWeight: FontWeight.w400,
            fontSize: SizeFont.h3.size),
        disabledHint: Text(
          selectedStatut ?? '',
          style: TextStyle(
              color: isEnabled ? Colors.black54 : Colors.black87,
              fontWeight: FontWeight.w400,
              fontSize: SizeFont.h3.size),
        ),
      ),
    );
  }

  Widget _buildReadOnlyTextField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: TextEditingController(text: value ?? ''),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
          enabled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
            ),
          ),
        ),
        style: TextStyle(
          color: Colors.black54,
          fontSize: SizeFont.h3.size,
        ),
      ),
    );
  }

  Widget _buildModifyTextField(
      String label, TextEditingController controller, FocusNode focusNode,
      {int maxLines = 1, int minLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: maxLines,
              minLines: minLines,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                ),
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: SizeFont.h3.size,
              ),
            ),
          ),
          if (focusNode.hasFocus)
            IconButton(
              onPressed: () {
                focusNode.unfocus();
              },
              icon: Icon(Icons.check),
            ),
        ],
      ),
    );
  }

  _loadProperty() {
    name.text = widget.lot.nameProp == "" || widget.lot.nameProp == null
        ? 'Définissez un nom pour votre bien.'
        : widget.lot.nameProp!;
    selectedStatut = widget.lot.type;
    setState(() {});
  }
}
