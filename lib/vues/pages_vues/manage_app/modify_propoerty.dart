import 'package:konodal/controllers/features/load_prefered_data.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/handlers/colors_utils.dart';
import 'package:konodal/controllers/providers/name_lot_provider.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/pages_vues/manage_app/modify_prop_details.dart';
import 'package:konodal/vues/pages_vues/manage_app/modify_prop_info_loc.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:konodal/vues/widget_view/page_widget/color_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, Consumer;
import 'package:provider/provider.dart';

class ModifyProperty extends ConsumerStatefulWidget {
  final Lot lot;
  final String idLotSelected;
  final String uid;
  final Function(Color) newColor;

  const ModifyProperty({
    super.key,
    required this.lot,
    required this.uid,
    required this.idLotSelected,
    required this.newColor,
  });

  @override
  ConsumerState<ModifyProperty> createState() => _ModifyPropertyState();
}

class _ModifyPropertyState extends ConsumerState<ModifyProperty> {
  late final ILotRepository lotServices;
  final TextEditingController name = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();

  String? selectedStatut;
  bool isProprietaire = false;
  late Color _backgroundColor;

  @override
  void initState() {
    super.initState();
    lotServices = ref.read(lotRepositoryProvider);
    isProprietaire = widget.lot.idProprietaire?.contains(widget.uid) ?? false;
    nameFocusNode.addListener(() => setState(() {}));
    name.addListener(_handleTextChange);
    _loadProperty();
  }

  void _loadProperty() {
    name.text = widget.lot.userLotDetails['nameLot']??"";
    selectedStatut = widget.lot.type;
    _backgroundColor =
        ColorUtils.fromHex(widget.lot.userLotDetails['colorSelected']);
    setState(() {});
  }

  void _handleTextChange() {
    if (name.text.length > 30) {
      name.text = name.text.substring(0, 30);
      name.selection = TextSelection.fromPosition(
        TextPosition(offset: name.text.length),
      );
    }
  }

  void _handleSubmit(String field, String label, String value) async {
    final result = await lotServices.updateNameLot(
        widget.uid, widget.lot.id!, capitalizeFirstLetter(value));

    if (result.isFailure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur lors de la mise à jour du nom du lot")),
        );
      }
      return;
    }

    if (!mounted) return;

    final nameLotProvider =
        Provider.of<NameLotProvider>(context, listen: false);
    nameLotProvider.updateNameLot(value);

    final loadService = LoadPreferedData();
    Lot? currentLot = await loadService.loadPreferedLot(widget.uid);
    if (currentLot != null) {
      currentLot.userLotDetails['nameLot'] = value;
      await loadService.savePreferedLot(widget.uid, currentLot);
    }
    widget.lot.userLotDetails['nameLot'] = value;
    setState(() {});
  }

  void _updateSelectedColor(Color newColor) {
    setState(() => _backgroundColor = newColor);
    widget.newColor(newColor);
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    name.removeListener(_handleTextChange);
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<NameLotProvider>(
          builder: (context, nameLotProvider, child) {
            final nameLot = widget.lot.userLotDetails['nameLot'];
            final providerName = nameLotProvider.name;

            final displayName = (nameLot != null && nameLot.isNotEmpty)
                ? nameLot
                : (providerName.isNotEmpty
                    ? providerName
                    : "${widget.lot.residenceData['name']} ${widget.lot.batiment}${widget.lot.lot}");

            return MyTextStyle.lotName(
              displayName,
              Colors.black87,
              SizeFont.h1.size,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSectionTitle("Paramètres"),
            _buildColorPicker(),
            const Divider(),
            CustomTextFieldWidget(
              label: 'Nom',
              text: 'Donner un nom à votre bien',
              controller: name,
              focusNode: nameFocusNode,
              field: 'nameLot',
              onSubmit: _handleSubmit,
              refresh: () => setState(() {}),
              isEditable: true,
              maxLines: 1,
              minLines: 1,
            ),
            const SizedBox(height: 30),
            _buildSectionTitle("Informations"),
            _buildNavigationTile(
              "Fiche du bien",
              () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ModifyPropDetails(
                      idLotSelected: widget.idLotSelected,
                      lot: widget.lot,
                      uid: widget.uid,
                    ),
                  ),
                );
              },
              const Icon(Icons.home_outlined, color: Colors.black87),
            ),
            Visibility(
              visible: widget.lot.idProprietaire!.contains(widget.uid),
              child: Column(
                children: [
                  _buildNavigationTile(
                    "Ma gestion locative",
                    () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => ModifyPropInfoLoc(
                            idLotSelected: widget.idLotSelected,
                            lot: widget.lot,
                            uid: widget.uid,
                          ),
                        ),
                      );
                    },
                    const Icon(Icons.manage_accounts_outlined,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: _buildDeleteButton(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        MyTextStyle.lotDesc(title, SizeFont.h2.size, FontStyle.italic),
      ],
    );
  }

  Widget _buildColorPicker() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ColorView(
              uiserId: widget.uid,
              lot: widget.lot,
              idLotSelected: widget.idLotSelected,
              onColorSelected: (color) => _updateSelectedColor(color),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _backgroundColor,
                  radius: 10,
                ),
                const SizedBox(width: 15),
                Text(
                  "Couleur du bien",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeFont.h3.size,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_right_outlined, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile(String label, VoidCallback onTap, Icon icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.all(20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: const Color(0xFFF5F6F9),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            icon,
            const SizedBox(width: 20),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: MyTextStyle.postDesc(
                  label,
                  SizeFont.h3.size,
                  Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF757575),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      //height: 50,
     // width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: SizedBox(
        child: ButtonAdd(
          function: _detachLot,
          text: "Détacher ce lot",
          color: Colors.black26,
          horizontal: 30,
          vertical: 10,
          size: SizeFont.h3.size,
        ),
      ),
    );
  }

  // L'inverse du rattachement (attach_existing_lot_page.dart) : l'utilisateur
  // se retire lui-même de ce lot (déménagement, vente...), il ne le supprime
  // pas - la suppression du lot reste réservée à un CS member/admin depuis
  // Gestion résidence > Gestion des lots.
  Future<void> _detachLot() async {
    final residenceName = widget.lot.residenceData['name'] ?? 'cette résidence';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: MyTextStyle.lotName(
            "Détacher ce lot", Colors.black87, SizeFont.h2.size),
        content: MyTextStyle.postDesc(
          "Si vous déménagez ou avez vendu ce bien, vous pouvez vous en "
          "détacher : vous perdrez immédiatement l'accès à $residenceName. "
          "Cette action est définitive. Confirmez-vous ce détachement ?",
          SizeFont.h3.size,
          Colors.black54,
          fontweight: FontWeight.normal,
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: MyTextStyle.lotName(
                "Annuler", Colors.black54, SizeFont.h3.size, FontWeight.normal),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: MyTextStyle.lotName("Détacher", Colors.red[800]!,
                SizeFont.h3.size, FontWeight.normal),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final result = isProprietaire
        ? await lotServices.removeIdProprietaire(
            widget.lot.residenceId, widget.lot.id!, widget.uid)
        : await lotServices.removeIdLocataire(
            widget.lot.residenceId, widget.lot.id!, widget.uid);

    if (!mounted) return;

    result.when(
      success: (_) => Navigator.pop(context),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du détachement : $error"),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }
}
