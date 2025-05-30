import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_user.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/income_entry.dart';
import 'package:connect_kasa/models/enum/tenant_list.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyTenantFolder extends StatefulWidget {
  final String uid;
  final Color color;
  final String refLot;

  const MyTenantFolder({
    super.key,
    required this.uid,
    required this.color,
    required this.refLot,
  });

  @override
  State<MyTenantFolder> createState() => _MyTenantFolderState();
}

class _MyTenantFolderState extends State<MyTenantFolder> {
  final DataBasesUserServices _userServices = DataBasesUserServices();
  UserInfo? tenantUser;
  bool isLoading = true;
  List<IncomeEntry> incomeEntries = [];

  // Controllers
  final TextEditingController profession = TextEditingController();
  final TextEditingController typeContract = TextEditingController();
  final TextEditingController entryJobDate = TextEditingController();
  final TextEditingController salary = TextEditingController();
  final TextEditingController housingAllowance = TextEditingController();
  final TextEditingController familyAllowance = TextEditingController();
  final TextEditingController additionalIncome = TextEditingController();

  // FocusNodes (si édition future)
  final FocusNode professionFocus = FocusNode();
  final FocusNode contractFocus = FocusNode();
  final FocusNode salaryFocus = FocusNode();

  String contactType = "";

  @override
  void initState() {
    super.initState();
    fetchTenantUser();
  }

  Future<void> fetchTenantUser() async {
    final user = await _userServices.getUserWithInfo(widget.uid);
    if (mounted) {
      setState(() {
        tenantUser = user;
        isLoading = false;
      });

      if (tenantUser != null) {
        profession.text = tenantUser!.profession ?? "";
        typeContract.text = tenantUser!.typeContract ?? "";
        // salary.text = tenantUser!.salary ?? "";

        if (tenantUser!.entryJobDate != null) {
          entryJobDate.text = DateFormat('dd/MM/yyyy')
              .format(tenantUser!.entryJobDate!.toDate());
        }

        incomeEntries = List<IncomeEntry>.from(tenantUser!.incomes ?? []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (tenantUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Aucun locataire trouvé.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            "Dossier du locataire", Colors.black87, SizeFont.h1.size),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyTextStyle.lotName(
              "Mon emploi actuel",
              Colors.black,
              SizeFont.h2.size,
            ),
            const SizedBox(height: 10),
            CustomTextFieldWidget(
              controller: profession,
              label: "Profession",
              value: profession.text,
              isEditable: true,
            ),
            MyDropDownMenu(
              width,
              "Type de contrat",
              "Type de contrat",
              false,
              items: TenantList.jobcontractList(),
              onValueChanged: (value) {
                setState(() {
                  contactType = value;
                });
              },
            ),

            CustomTextFieldWidget(
              label: "Date d'entrée en fonction",
              controller: entryJobDate,
              isEditable: true,
              pickDate: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  entryJobDate.text =
                      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                }
              },
            ),
            const SizedBox(height: 20),
            MyTextStyle.lotName(
              "Mes revenus",
              Colors.black,
              SizeFont.h2.size,
            ),
            const SizedBox(height: 10),

            ...incomeEntries.asMap().entries.map((entry) {
              int index = entry.key;
              IncomeEntry income = entry.value;

              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: MyDropDownMenu(
                      width,
                      "Type de revenu",
                      income.label.isEmpty ? "Type de revenu" : income.label,
                      false,
                      items: TenantList.incomesType(),
                      onValueChanged: (value) {
                        setState(() {
                          incomeEntries[index] =
                              IncomeEntry(label: value, amount: income.amount);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomTextFieldWidget(
                      label: "Montant",
                      controller: TextEditingController(text: income.amount),
                      isEditable: true,
                      onChanged: (val) {
                        incomeEntries[index] =
                            IncomeEntry(label: income.label, amount: val);
                      },
                    ),
                  ),
                ],
              );
            }).toList(),

            const SizedBox(height: 15),

            Center(
              child: ButtonAdd(
                color: widget.color,
                icon: Icons.add,
                text: "Ajouter un revenu",
                size: SizeFont.h3.size,
                horizontal: 20,
                vertical: 10,
                colorText: Colors.white,
                borderColor: Colors.grey.shade300,
                function: addIncomeEntry,
              ),
            ),

            const SizedBox(height: 30),
            MyTextStyle.lotName(
              "Documents & justificatifs",
              Colors.black,
              SizeFont.h2.size,
            ),
            const SizedBox(height: 10),
            // TenantDocumentsGrid(tenant: tenantUser!), // à réactiver si utilisé

            Center(
              child: ButtonAdd(
                  color: Colors.transparent,
                  text: "Enregistrer",
                  size: SizeFont.h3.size,
                  horizontal: 20,
                  vertical: 10,
                  colorText: widget.color,
                  borderColor: widget.color,
                  function: saveUserInfo),
            ),
          ],
        ),
      ),
    );
  }

  void saveUserInfo() async {
    if (tenantUser == null) return;

    // Construire un nouvel UserInfo à partir des champs modifiés
    UserInfo updatedUser = UserInfo(
      uid: tenantUser!.uid,
      email: tenantUser!.email,
      name: tenantUser!.name,
      surname: tenantUser!.surname,
      pseudo: tenantUser!.pseudo,
      approved: tenantUser!.approved,
      profilPic: tenantUser!.profilPic ?? '',
      privacyPolicy: tenantUser!.privacyPolicy,
      birthday: tenantUser!.birthday,
      sex: tenantUser!.sex,
      nationality: tenantUser!.nationality,
      placeOfborn: tenantUser!.placeOfborn,

      // Champs spécifiques modifiables
      profession: profession.text,
      typeContract:
          contactType.isEmpty ? tenantUser!.typeContract : contactType,
      entryJobDate: _parseDate(entryJobDate.text) ?? tenantUser!.entryJobDate,

      incomes: incomeEntries,
      dependent: tenantUser!.dependent,
      familySituation: tenantUser!.familySituation,
      phone: tenantUser!.phone,

      // Tu peux ajouter d'autres champs si besoin
    );

    bool success = await _userServices.updateUserInfo(updatedUser);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informations mises à jour avec succès")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la mise à jour")),
      );
    }
  }

// Helper pour parser la date en Timestamp
  Timestamp? _parseDate(String dateStr) {
    try {
      DateTime dt = DateFormat('dd/MM/yyyy').parse(dateStr);
      return Timestamp.fromDate(dt);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    profession.dispose();
    typeContract.dispose();
    entryJobDate.dispose();
    salary.dispose();
    housingAllowance.dispose();
    familyAllowance.dispose();
    additionalIncome.dispose();
    professionFocus.dispose();
    contractFocus.dispose();
    salaryFocus.dispose();
    super.dispose();
  }

  void addIncomeEntry() {
    setState(() {
      incomeEntries.add(IncomeEntry(label: '', amount: ''));
    });
  }
}
