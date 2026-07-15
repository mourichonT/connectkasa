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
import 'package:konodal/vues/widget_view/components/app_loader.dart';
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
  Future<List<Lot>>? _residenceLotsFuture;

  @override
  void initState() {
    super.initState();
    lotServices = ref.read(lotRepositoryProvider);
    isProprietaire = widget.lot.idProprietaire?.contains(widget.uid) ?? false;
    nameFocusNode.addListener(() => setState(() {}));
    name.addListener(_handleTextChange);
    _loadProperty();
    if (isProprietaire) {
      _refreshResidenceLots();
    }
  }

  void _refreshResidenceLots() {
    _residenceLotsFuture = lotServices
        .getLotByResidence(widget.lot.residenceId)
        .then((result) => result.when(success: (v) => v, failure: (_) => <Lot>[]));
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
                  // Un lot enfant (parentLotId défini) ne gère plus sa
                  // liaison depuis sa propre fiche : la gestion (regrouper/
                  // dégrouper/délier) se fait exclusivement depuis le lot
                  // PARENT, pour éviter une double saisie/deux points de
                  // contrôle sur la même relation.
                  if (widget.lot.parentLotId == null) ...[
                    const SizedBox(height: 30),
                    _buildSectionTitle("Lots liés"),
                    _buildLinkedLotsSection(),
                  ],
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

  // Aligné sur _buildSectionHeader (guarantor_detail.dart) : gras, non
  // italique - le style utilisé par les autres pages pour un titre de
  // section, contrairement à l'italique utilisé ici auparavant.
  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        MyTextStyle.lotDesc(
            title, SizeFont.h2.size, FontStyle.normal, FontWeight.bold),
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

  String _labelForLot(Lot lot) {
    final parts = <String>[];
    if (lot.typeLot.isNotEmpty) parts.add(lot.typeLot);
    if ((lot.batiment ?? '').isNotEmpty) parts.add('Bât. ${lot.batiment}');
    if ((lot.lot ?? '').isNotEmpty) parts.add('N°${lot.lot}');
    return parts.isEmpty ? lot.refLot : parts.join(' - ');
  }

  /// Rattachement de lots d'une même résidence (ex: un parking rattaché à
  /// un appartement) : réservé au propriétaire (vérifié par l'appelant via
  /// Visibility). idProprietaire/idLocataire sont ensuite synchronisés côté
  /// serveur (sync_lot_tenants) - cf. mémoire project_lot_parent_child.
  /// N'est appelé QUE pour un lot sans parent (cf. build()) : un lot enfant
  /// ne gère plus sa liaison depuis sa propre fiche (double saisie évitée),
  /// cette gestion (regrouper/dégrouper/délier) se fait exclusivement
  /// depuis la fiche du parent, sur chaque enfant listé ci-dessous.
  Widget _buildLinkedLotsSection() {
    return FutureBuilder<List<Lot>>(
      future: _residenceLotsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: AppLoader()),
          );
        }
        final allLots = snapshot.data ?? <Lot>[];

        final children =
            allLots.where((l) => l.parentLotId == widget.lot.id).toList();

        // isLinkable conditionne uniquement le rôle ENFANT (ce lot devenant
        // enfant d'un autre) - un lot peut toujours servir de PARENT
        // (attacher un autre lot à lui), quel que soit son propre
        // isLinkable : un appartement (isLinkable=false) ne peut pas
        // devenir enfant, mais doit pouvoir attacher un parking à lui-même.
        //
        // Dans les deux cas, uniquement les lots de la résidence dont je
        // suis déjà propriétaire (cohérent avec la règle Firestore) - sinon
        // le choix mènerait à un refus d'écriture.
        final eligibleParents = allLots
            .where((l) =>
                l.id != widget.lot.id &&
                l.parentLotId == null &&
                (l.idProprietaire?.contains(widget.uid) ?? false))
            .toList();
        final eligibleChildren = allLots
            .where((l) =>
                l.id != widget.lot.id &&
                l.parentLotId == null &&
                l.isLinkable &&
                (l.idProprietaire?.contains(widget.uid) ?? false))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (children.isNotEmpty) ...[
              const SizedBox(height: 20),
              for (final child in children)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color(0xFFF5F6F9),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.home_work_outlined,
                          size: 24, color: Colors.black87),
                      const SizedBox(width: 15),
                      Expanded(
                        child: MyTextStyle.postDesc(
                          _labelForLot(child),
                          SizeFont.h3.size,
                          Colors.black87,
                        ),
                      ),
                      Switch(
                        value: child.groupedWithParent,
                        onChanged: (value) => _toggleChildGrouped(child, value),
                      ),
                      IconButton(
                        icon: const Icon(Icons.link_off, color: Colors.black87),
                        tooltip: "Délier ce lot",
                        onPressed: () => _unlinkChild(child),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 15),
            ],
            if (widget.lot.isLinkable)
              _buildNavigationTile(
                "Lier ce lot à un autre",
                eligibleParents.isEmpty
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Aucun autre lot disponible dans cette résidence.")),
                        )
                    : () => _showLinkLotPicker(eligibleParents),
                const Icon(Icons.link, color: Colors.black87),
              ),
            const SizedBox(height: 10),
            _buildNavigationTile(
              "Rattacher un autre lot à celui-ci",
              eligibleChildren.isEmpty
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Aucun lot rattachable disponible dans cette résidence.")),
                      )
                  : () => _showAttachChildPicker(eligibleChildren),
              const Icon(Icons.add_link, color: Colors.black87),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLinkLotPicker(List<Lot> eligibleParents) async {
    final chosen = await showModalBottomSheet<Lot>(
      showDragHandle: true,
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: eligibleParents
              .map((lot) => ListTile(
                    title: Text(_labelForLot(lot)),
                    onTap: () => Navigator.pop(context, lot),
                  ))
              .toList(),
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: MyTextStyle.lotName(
            "Lier ce lot", Colors.black87, SizeFont.h2.size),
        content: MyTextStyle.postDesc(
          "Ce lot sera rattaché à ${_labelForLot(chosen)} : le même "
          "locataire y sera automatiquement affecté (locataire commun). "
          "Vous pourrez dégrouper ensuite si besoin. Confirmez-vous ?",
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
            child: MyTextStyle.lotName(
                "Lier", Colors.black87, SizeFont.h3.size, FontWeight.normal),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await lotServices.linkLotToParent(
        widget.lot.residenceId, widget.lot.id!, chosen.id!);

    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() {
          widget.lot.parentLotId = chosen.id;
          widget.lot.groupedWithParent = true;
          _refreshResidenceLots();
        });
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la liaison : $error"),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }

  /// Inverse de _showLinkLotPicker : ici widget.lot RESTE le parent, et
  /// c'est le lot choisi qui devient l'enfant (candidats déjà filtrés sur
  /// isLinkable=true par l'appelant).
  Future<void> _showAttachChildPicker(List<Lot> eligibleChildren) async {
    final chosen = await showModalBottomSheet<Lot>(
      showDragHandle: true,
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: eligibleChildren
              .map((lot) => ListTile(
                    title: Text(_labelForLot(lot)),
                    onTap: () => Navigator.pop(context, lot),
                  ))
              .toList(),
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: MyTextStyle.lotName(
            "Rattacher ce lot", Colors.black87, SizeFont.h2.size),
        content: MyTextStyle.postDesc(
          "${_labelForLot(chosen)} sera rattaché à ce lot : le même "
          "locataire y sera automatiquement affecté (locataire commun). "
          "Vous pourrez dégrouper ensuite si besoin. Confirmez-vous ?",
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
            child: MyTextStyle.lotName(
                "Rattacher", Colors.black87, SizeFont.h3.size, FontWeight.normal),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await lotServices.linkLotToParent(
        widget.lot.residenceId, chosen.id!, widget.lot.id!);

    if (!mounted) return;
    result.when(
      success: (_) => setState(_refreshResidenceLots),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du rattachement : $error"),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }

  /// Délie un enfant depuis la fiche du PARENT (widget.lot) : un lot enfant
  /// ne peut plus le faire depuis sa propre fiche (gestion exclusivement
  /// côté parent, cf. _buildLinkedLotsSection).
  Future<void> _unlinkChild(Lot child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: MyTextStyle.lotName(
            "Délier ce lot", Colors.black87, SizeFont.h2.size),
        content: MyTextStyle.postDesc(
          "${_labelForLot(child)} ne sera plus rattaché à ce lot : son "
          "locataire actuel est conservé, mais pourra être géré "
          "indépendamment. Confirmez-vous ?",
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
            child: MyTextStyle.lotName("Délier", Colors.red[800]!,
                SizeFont.h3.size, FontWeight.normal),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result =
        await lotServices.unlinkLot(widget.lot.residenceId, child.id!);

    if (!mounted) return;
    result.when(
      success: (_) => setState(_refreshResidenceLots),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la déliaison : $error"),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }

  // Partagé par _toggleGrouped (ce lot est l'enfant) et _toggleChildGrouped
  // (un des enfants de ce lot, vu depuis le parent) : le dégroupement rend
  // au lot un locataire potentiellement indépendant - il redevient alors
  // visible dans "Gestion des biens"/le sélecteur de lot (masqué tant qu'il
  // reste groupé, cf. project_lot_parent_child) - assez impactant pour
  // justifier une confirmation dans les deux sens.
  Future<bool> _confirmGroupToggle(bool turningOn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: MyTextStyle.lotName(
            turningOn ? "Regrouper ce lot" : "Dégrouper ce lot",
            Colors.black87,
            SizeFont.h2.size),
        content: MyTextStyle.postDesc(
          turningOn
              ? "Le locataire actuel de ce lot sera remplacé par celui du "
                  "lot parent. Confirmez-vous ?"
              : "Ce lot pourra avoir un locataire indépendant du lot "
                  "parent (le propriétaire reste partagé). Il redeviendra "
                  "visible comme un bien à part entière. Confirmez-vous ?",
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
            child: MyTextStyle.lotName(
                turningOn ? "Regrouper" : "Dégrouper",
                Colors.black87,
                SizeFont.h3.size,
                FontWeight.normal),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Bascule regroupé/dégroupé pour un enfant, depuis la fiche du lot
  /// PARENT (widget.lot) : un enfant ne peut plus le faire depuis sa
  /// propre fiche (gestion exclusivement côté parent).
  Future<void> _toggleChildGrouped(Lot child, bool value) async {
    if (!await _confirmGroupToggle(value) || !mounted) return;

    final result = await lotServices.setGroupedWithParent(
        widget.lot.residenceId, child.id!, value);

    if (!mounted) return;
    result.when(
      success: (_) => setState(_refreshResidenceLots),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la mise à jour : $error"),
          backgroundColor: Colors.red,
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
