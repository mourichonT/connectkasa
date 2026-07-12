import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModifyPropDetails extends ConsumerStatefulWidget {
  final Lot lot;
  final String idLotSelected;
  final String uid;

  const ModifyPropDetails({
    super.key,
    required this.lot,
    required this.uid,
    required this.idLotSelected,
  });

  @override
  ConsumerState<ModifyPropDetails> createState() => ModifyPropDetailsState();
}

class ModifyPropDetailsState extends ConsumerState<ModifyPropDetails> {
  late final ILotRepository lotServices;

  TextEditingController name = TextEditingController();
  String? selectedStatut;
  bool isProprietaire = false;

  FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    lotServices = ref.read(lotRepositoryProvider);
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
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          widget.lot.userLotDetails['nameLot'] != "" ||
                  widget.lot.userLotDetails['nameLot'] != null
              ? name.text
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
            _buildReadOnlyTextField('Lot', widget.lot.lot),
            _buildReadOnlyTextField('Adresse',
                "${widget.lot.residenceData["numero"]} ${widget.lot.residenceData["voie"]} ${widget.lot.residenceData["street"]}"),
            _buildReadOnlyTextField(
                'Code Postal', widget.lot.residenceData["zipCode"]),
            _buildReadOnlyTextField('Ville', widget.lot.residenceData["city"]),
            const SizedBox(
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

  _loadProperty() {
    name.text = widget.lot.userLotDetails['nameLot'];
    selectedStatut = widget.lot.type;
    setState(() {});
  }
}
