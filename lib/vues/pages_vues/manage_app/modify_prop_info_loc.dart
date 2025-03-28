import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/statut_list.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModifyPropInfoLoc extends StatefulWidget {
  final Lot lot;
  final String refLotSelected;
  final String uid;

  const ModifyPropInfoLoc({
    super.key,
    required this.lot,
    required this.uid,
    required this.refLotSelected,
  });

  @override
  State<StatefulWidget> createState() => ModifyPropInfoLocState();
}

class ModifyPropInfoLocState extends State<ModifyPropInfoLoc> {
  DataBasesLotServices lotServices = DataBasesLotServices();

  TextEditingController nameSyndic = TextEditingController();
  String? selectedStatut;
  bool isProprietaire = false;

  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );
  FocusNode nameSyndicFocusNode = FocusNode();
  bool delegated = false;

  void updateBool(bool delegatedBool) {
    setState(() {
      delegated = delegatedBool;
    });
  }

  @override
  void initState() {
    super.initState();
    isProprietaire = widget.lot.idProprietaire?.contains(widget.uid) ?? false;
    nameSyndicFocusNode.addListener(() => setState(() {}));
    nameSyndic.addListener(_handleTextChange);
    _loadProperty();
  }

  @override
  void dispose() {
    nameSyndicFocusNode.dispose();
    nameSyndic.removeListener(_handleTextChange);
    nameSyndic.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    if (nameSyndic.text.length > 30) {
      nameSyndic.text = nameSyndic.text.substring(0, 30);
      nameSyndic.selection = TextSelection.fromPosition(
          TextPosition(offset: nameSyndic.text.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          "Ma gestion locative",
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _buildDropDownMenu(width, 'Statut'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: width / 1.5,
                  child: MyTextStyle.annonceDesc(
                      "Souhaitez-vous déléguer la gestion de votre bien ",
                      SizeFont.h3.size,
                      2),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    thumbIcon: thumbIcon,
                    value: delegated,
                    onChanged: (bool value) {
                      setState(() {
                        delegated = value;
                        updateBool(delegated);
                      });
                    },
                  ),
                ),
              ],
            ),
            Visibility(
              visible: delegated,
              child: Column(
                children: [
                  _buildModifyTextField(
                    "Saissez le nom de votre agence",
                    'Rechercher une agence',
                    nameSyndic,
                    nameSyndicFocusNode,
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 80,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropDownMenu(double width, String label) {
    List<String> statuts = ImmoList.statutList();
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
          border: const UnderlineInputBorder(
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
          labelStyle: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
          enabled: false,
          border: const UnderlineInputBorder(
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
      TextEditingController controller, FocusNode focusNode,
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
                labelStyle: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
                border: const UnderlineInputBorder(
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
              icon: const Icon(Icons.search),
            )
        ],
      ),
    );
  }

  _loadProperty() {
    //nameSyndic.text =
    selectedStatut = widget.lot.type;
    //_backgroundColor = Color(
    // int.parse(widget.lot.colorSelected.substring(2), radix: 16) +
    //     0xFF000000);
    setState(() {});
  }
}
