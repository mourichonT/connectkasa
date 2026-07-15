import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/pages_vues/manage_app/request_lot_modification_page.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/cupertino.dart';
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
  Future<List<Lot>>? _childLotsFuture;

  FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    lotServices = ref.read(lotRepositoryProvider);
    isProprietaire = widget.lot.idProprietaire?.contains(widget.uid) ?? false;
    nameFocusNode.addListener(() => setState(() {}));
    name.addListener(_handleTextChange);
    _loadProperty();
    _childLotsFuture = lotServices
        .getChildLots(widget.lot.residenceId, widget.lot.id!)
        .then((result) => result.when(success: (v) => v, failure: (_) => <Lot>[]));
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: <Widget>[
            _buildLotCard("Lot principal", widget.lot,
                includeResidenceInfo: true),
            _buildChildLotsSection(),
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
              function: () async {
                final children =
                    await (_childLotsFuture ?? Future.value(<Lot>[]));
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => RequestLotModificationPage(
                      uid: widget.uid,
                      mainLot: widget.lot,
                      childLots: children,
                    ),
                  ),
                );
              },
              text: "Demander une modification",
              color: Colors.black26,
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size),
        ),
      ),
    );
  }

  // Un lot rattaché (parentLotId pointant vers widget.lot) partage le même
  // propriétaire (toujours) et, si groupé, le même locataire : sa fiche
  // reste consultable ici plutôt que par sa propre page, potentiellement
  // inatteignable tant qu'il reste groupé (cf. project_lot_parent_child).
  Widget _buildChildLotsSection() {
    return FutureBuilder<List<Lot>>(
      future: _childLotsFuture,
      builder: (context, snapshot) {
        final children = snapshot.data ?? <Lot>[];
        if (children.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children)
              _buildLotCard("Lot rattaché", child,
                  includeResidenceInfo: false),
          ],
        );
      },
    );
  }

  // Même regroupement par carte que la gestion des lots (manage_list_lot.dart)
  // et la gestion de la résidence (management_res_info_g.dart) : un Card
  // (élévation 2, coins arrondis) contenant les champs en lecture seule
  // (CustomTextFieldWidget, isEditable: false) - includeResidenceInfo est
  // omis pour un lot rattaché, déjà dans la même résidence que le principal.
  Widget _buildLotCard(String title, Lot lot,
      {required bool includeResidenceInfo}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyTextStyle.lotName(title, Colors.black87, SizeFont.h3.size),
            const SizedBox(height: 10),
            CustomTextFieldWidget(label: 'Type', value: lot.typeLot),
            if (includeResidenceInfo)
              CustomTextFieldWidget(
                  label: 'Résidence',
                  value: lot.residenceData['name']?.toString() ?? ''),
            CustomTextFieldWidget(label: 'Référence Lot', value: lot.refLot),
            CustomTextFieldWidget(label: 'Bâtiment', value: lot.batiment ?? ''),
            CustomTextFieldWidget(label: 'Lot', value: lot.lot ?? ''),
            if (includeResidenceInfo) ...[
              CustomTextFieldWidget(
                  label: 'Adresse',
                  value: lot.residenceAddress['street']?.toString() ?? ''),
              CustomTextFieldWidget(
                  label: 'Code Postal',
                  value: lot.residenceAddress['zipCode']?.toString() ?? ''),
              CustomTextFieldWidget(
                  label: 'Ville',
                  value: lot.residenceAddress['city']?.toString() ?? ''),
            ],
          ],
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
