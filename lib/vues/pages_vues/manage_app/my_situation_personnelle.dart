import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/dependent_entry.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/current_user_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/nationality_list.dart';
import 'package:konodal/models/enum/tenant_list.dart';
import 'package:konodal/models/pages_models/conjoint_info.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Situations familiales impliquant de renseigner un conjoint/partenaire -
/// doit rester synchronisé avec TenantList.situationsFamiliales().
const _situationsAvecConjoint = {
  "Marié(e)",
  "Pacsé(e)",
  "Concubinage (union libre)",
};

/// Situation familiale (marié/divorcé/veuf...) et personnes à charge : ces
/// deux champs (familySituation, dependents sur UserInfo) existaient déjà
/// côté modèle/Firestore et étaient affichés côté propriétaire
/// (tenant_detail.dart) mais n'avaient jamais eu de page de saisie côté
/// locataire.
class MySituationPersonnelle extends ConsumerStatefulWidget {
  final String uid;
  final Color color;

  const MySituationPersonnelle({
    super.key,
    required this.uid,
    required this.color,
  });

  @override
  ConsumerState<MySituationPersonnelle> createState() =>
      _MySituationPersonnelleState();
}

class _MySituationPersonnelleState
    extends ConsumerState<MySituationPersonnelle> {
  late final _userServices = ref.read(userRepositoryProvider);
  UserInfo? tenantUser;
  String _familySituation = "";
  List<DependentEntry> _dependents = [];
  bool isLoading = true;

  final TextEditingController _conjointNameController =
      TextEditingController();
  final TextEditingController _conjointSurnameController =
      TextEditingController();
  String _conjointNationality = "";
  final TextEditingController _conjointBirthdayController =
      TextEditingController();
  Timestamp? _conjointBirthdayValue;

  bool get _showConjointSection =>
      _situationsAvecConjoint.contains(_familySituation);

  @override
  void initState() {
    super.initState();
    _fetchTenantUser();
  }

  @override
  void dispose() {
    _conjointNameController.dispose();
    _conjointSurnameController.dispose();
    _conjointBirthdayController.dispose();
    super.dispose();
  }

  Future<void> _fetchTenantUser() async {
    final user = await _userServices
        .getUserWithInfo(widget.uid)
        .then((result) => result.when(success: (v) => v, failure: (_) => null));
    if (!mounted) return;
    setState(() {
      tenantUser = user;
      isLoading = false;
      _familySituation = user?.familySituation ?? "";
      _dependents = List<DependentEntry>.from(user?.dependents ?? []);
      _conjointNameController.text = user?.conjoint.name ?? '';
      _conjointSurnameController.text = user?.conjoint.surname ?? '';
      _conjointNationality = user?.conjoint.nationality ?? '';
      _conjointBirthdayValue = user?.conjoint.birthday;
      _conjointBirthdayController.text = _conjointBirthdayValue != null
          ? DateFormat('dd/MM/yyyy').format(_conjointBirthdayValue!.toDate())
          : '';
    });
  }

  Future<void> _save() async {
    if (tenantUser == null) return;
    final updatedUser = UserInfo(
      uid: tenantUser!.uid,
      email: tenantUser!.email,
      name: tenantUser!.name,
      surname: tenantUser!.surname,
      pseudo: tenantUser!.pseudo,
      isApproved: tenantUser!.isApproved,
      createdDate: tenantUser!.createdDate,
      profilPic: tenantUser!.profilPic ?? '',
      privacyPolicy: tenantUser!.privacyPolicy,
      birthday: tenantUser!.birthday,
      sex: tenantUser!.sex,
      nationality: tenantUser!.nationality,
      placeOfborn: tenantUser!.placeOfborn,
      incomes: tenantUser!.incomes,
      jobIncomes: tenantUser!.jobIncomes,
      phone: tenantUser!.phone,
      address: tenantUser!.address,
      familySituation: _familySituation,
      dependents: _dependents,
      // Si la situation ne l'implique plus (retour à célibataire...), on
      // efface les infos du conjoint plutôt que de laisser des données
      // périmées en base.
      conjoint: _showConjointSection
          ? ConjointInfo(
              name: _conjointNameController.text,
              surname: _conjointSurnameController.text,
              nationality: _conjointNationality,
              birthday: _conjointBirthdayValue,
            )
          : ConjointInfo(),
    );

    final success = await _userServices
        .updateUserInfo(updatedUser)
        .then((result) => result.when(success: (v) => v, failure: (_) => false));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? "Situation personnelle enregistrée."
            : "Erreur lors de l'enregistrement."),
      ),
    );
    if (success) setState(() => tenantUser = updatedUser);
  }

  void _addDependent() {
    setState(() => _dependents.add(DependentEntry(type: '', count: '')));
  }

  void _removeDependent(int index) {
    setState(() => _dependents.removeAt(index));
  }

  List<Widget> _buildDependentsSection(double width) {
    return _dependents.asMap().entries.map((entry) {
      final index = entry.key;
      final dependent = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: MyDropDownMenu(
                    width,
                    "Catégorie",
                    dependent.type.isEmpty ? "Catégorie" : dependent.type,
                    false,
                    items: TenantList.typesPersonneCharge(),
                    onValueChanged: (value) {
                      setState(() => _dependents[index] =
                          DependentEntry(type: value, count: dependent.count));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: CustomTextFieldWidget(
                    text: "Nombre",
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: dependent.count),
                    isEditable: true,
                    onChanged: (val) {
                      _dependents[index] =
                          DependentEntry(type: dependent.type, count: val);
                    },
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _removeDependent(index),
              child: const Text("Supprimer cette catégorie"),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: AppLoader()),
      );
    }

    if (tenantUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Aucun locataire trouvé.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: MyTextStyle.lotName(
            "Ma situation personnelle", Colors.black87, SizeFont.h1.size),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyTextStyle.lotName(
                      "Situation familiale", Colors.black, SizeFont.h2.size),
                  const SizedBox(height: 10),
                  MyDropDownMenu(
                    width,
                    "Situation familiale",
                    _familySituation.isEmpty
                        ? "Situation familiale"
                        : _familySituation,
                    false,
                    items: TenantList.situationsFamiliales(),
                    onValueChanged: (value) {
                      setState(() => _familySituation = value);
                    },
                  ),
                  if (_showConjointSection) ...[
                    const SizedBox(height: 30),
                    MyTextStyle.lotName(
                        "Conjoint(e)", Colors.black, SizeFont.h2.size),
                    const SizedBox(height: 10),
                    CustomTextFieldWidget(
                      label: "Nom",
                      controller: _conjointNameController,
                      isEditable: true,
                      onChanged: (_) {},
                    ),
                    CustomTextFieldWidget(
                      label: "Prénom",
                      controller: _conjointSurnameController,
                      isEditable: true,
                      onChanged: (_) {},
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomTextFieldWidget(
                            label: "Date de naissance",
                            controller: _conjointBirthdayController,
                            isEditable: true,
                            pickDate: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate:
                                    _conjointBirthdayValue?.toDate() ??
                                        DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _conjointBirthdayValue =
                                      Timestamp.fromDate(pickedDate);
                                  _conjointBirthdayController.text =
                                      DateFormat('dd/MM/yyyy')
                                          .format(pickedDate);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: MyDropDownMenu(
                            width,
                            "Nationalité",
                            _conjointNationality.isEmpty
                                ? "Nationalité"
                                : _conjointNationality,
                            false,
                            items: NationalityList.all(),
                            onValueChanged: (value) {
                              setState(() => _conjointNationality = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 30),
                  MyTextStyle.lotName("Personnes à charge", Colors.black,
                      SizeFont.h2.size),
                  const SizedBox(height: 10),
                  ..._buildDependentsSection(width),
                  Center(
                    child: ButtonAdd(
                      color: Colors.transparent,
                      icon: Icons.add,
                      text: "Ajouter une personne à charge",
                      size: SizeFont.h3.size,
                      horizontal: 20,
                      vertical: 10,
                      colorText: widget.color,
                      borderColor: Colors.transparent,
                      function: _addDependent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: ButtonAdd(
                color: widget.color,
                text: "Enregistrer",
                size: SizeFont.h3.size,
                horizontal: 20,
                vertical: 10,
                colorText: Colors.white,
                borderColor: widget.color,
                function: _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
