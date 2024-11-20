import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/statut_list.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModifyPropDetails extends StatefulWidget {
  final Lot lot;
  final String refLotSelected;
  final String uid;

  const ModifyPropDetails({
    Key? key,
    required this.lot,
    required this.uid,
    required this.refLotSelected,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ModifyPropDetailsState();
}

class ModifyPropDetailsState extends State<ModifyPropDetails> {
  DataBasesLotServices lotServices = DataBasesLotServices();

  TextEditingController name = TextEditingController();
  String? selectedStatut;
  bool isProprietaire = false;

  late Color _backgroundColor;

  FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    isProprietaire = widget.lot.idProprietaire?.contains(widget.uid) ?? false;
    nameFocusNode.addListener(() => setState(() {}));
    name.addListener(_handleTextChange);
    _loadProperty();
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    name.removeListener(_handleTextChange);
    name.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    if (name.text.length > 30) {
      name.text = name.text.substring(0, 30);
      name.selection =
          TextSelection.fromPosition(TextPosition(offset: name.text.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          widget.lot.nameProp != null && widget.lot.nameProp != "" ||
                  widget.lot.nameLoc != null && widget.lot.nameLoc != ""
              ? name.text!
              : "${widget.lot.residenceData['name']} ${widget.lot.lot}",
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: <Widget>[
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
              text: "Demander une modification",
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

  Widget _buildModifyTextField(String hintText, String label,
      TextEditingController controller, FocusNode focusNode, String field,
      {int maxLines = 1, int minLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: maxLines,
              minLines: minLines,
              inputFormatters: [
                LengthLimitingTextInputFormatter(30),
              ],
              decoration: InputDecoration(
                hintText: hintText,
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
                setState(() {
                  controller.clear();
                });
              },
              icon: Icon(Icons.clear),
            ),
          if (focusNode.hasFocus)
            IconButton(
              onPressed: () {
                lotServices.updateLot(
                  widget.lot.residenceId,
                  widget.lot.refLot,
                  field,
                  controller.text,
                );
                setState(() {
                  // Mettre à jour le nom dans le lot après la validation
                  if (field == 'nameProp') {
                    widget.lot.newNameProp = controller.text;
                  } else {
                    widget.lot.newNameLoc = controller.text;
                  }
                });
                focusNode.unfocus();
              },
              icon: Icon(Icons.check),
            )
        ],
      ),
    );
  }

  _loadProperty() {
    name.text = isProprietaire ? widget.lot.nameProp : widget.lot.nameLoc;

    selectedStatut = widget.lot.type;
    _backgroundColor = Color(
        int.parse(widget.lot.colorSelected.substring(2), radix: 16) +
            0xFF000000);
    setState(() {});
  }
}
