import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/handlers/colors_utils.dart';
import 'package:connect_kasa/controllers/providers/name_lot_provider.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/modify_prop_details.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/modify_prop_info_loc.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/color_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModifyProperty extends StatefulWidget {
  final Lot lot;
  final String refLotSelected;
  final String uid;
  final Function(Color) newColor;

  const ModifyProperty({
    super.key,
    required this.lot,
    required this.uid,
    required this.refLotSelected,
    required this.newColor,
  });

  @override
  State<ModifyProperty> createState() => _ModifyPropertyState();
}

class _ModifyPropertyState extends State<ModifyProperty> {
  final DataBasesLotServices lotServices = DataBasesLotServices();
  final TextEditingController name = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();

  String? selectedStatut;
  bool isProprietaire = false;
  late Color _backgroundColor;

  @override
  void initState() {
    super.initState();
    isProprietaire = widget.lot.idProprietaire?.contains(widget.uid) ?? false;
    nameFocusNode.addListener(() => setState(() {}));
    name.addListener(_handleTextChange);
    _loadProperty();
  }

  void _loadProperty() {
    name.text = widget.lot.userLotDetails['nameLot'];
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
    lotServices.updateNameLot(widget.uid,
        "${widget.lot.residenceData['id']}-${widget.lot.refLot}", value);

    final nameLotProvider =
        Provider.of<NameLotProvider>(context, listen: false);
    nameLotProvider.updateNameLot(value);

    final loadService = LoadPreferedData();
    Lot? currentLot = await loadService.loadPreferedLot();
    if (currentLot != null) {
      currentLot.userLotDetails['nameLot'] = value;
      await loadService.savePreferedLot(currentLot);
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
                : (providerName != null && providerName.isNotEmpty
                    ? providerName
                    : "${widget.lot.residenceData['name']} ${widget.lot.lot}");

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
              field: widget.lot.userLotDetails['nameLot'],
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
                      refLotSelected: widget.refLotSelected,
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
                            refLotSelected: widget.refLotSelected,
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
              refLotSelected: widget.refLotSelected,
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
      height: 50,
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: Center(
        child: ButtonAdd(
          function: () {}, // À implémenter : suppression
          text: "Supprimer",
          color: Colors.black26,
          horizontal: 30,
          vertical: 10,
          size: SizeFont.h3.size,
        ),
      ),
    );
  }
}
