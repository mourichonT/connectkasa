import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/statut_post_list.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/my_multiselected_dropdown.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';

typedef FilterCallback = void Function({
  required List<String?> locationElement,
  required List<String?> type,
  required String dateFrom,
  required String dateTo,
  required List<String?> statut,
});

typedef ShowFilterCallback = void Function({required bool showFilter});

class FilterAllPostController extends StatefulWidget {
  final String residenceSelected;
  final String uid;
  final FilterCallback onFilterUpdate;
  final ShowFilterCallback updateShowFilter;

  const FilterAllPostController({
    super.key,
    required this.residenceSelected,
    required this.uid,
    required this.onFilterUpdate,
    required this.updateShowFilter,
  });

  @override
  State<StatefulWidget> createState() => FilterAllPostControllerState();
}

class FilterAllPostControllerState extends State<FilterAllPostController> {
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  final DataBasesResidenceServices _ResServices = DataBasesResidenceServices();
  late Future<List<Map<String, String>>> _allLocationsFuture;
  late Post post;
  final TypeList _typeList = TypeList();
  final GlobalKey<FormFieldState> _multiSelectKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _multiStatutKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _multiTypeKey = GlobalKey<FormFieldState>();
  List<String?> _selectedEmplacement = [];
  List<String?> _selectedStatut = [];
  List<String?> labelsType = [];
  bool _showFilter = true;
  final List<String> listStatu = StatutPostList.values
      .where((e) => e != StatutPostList.empty)
      .map((e) => e.label)
      .toList();

  @override
  void initState() {
    super.initState();
    _allLocationsFuture =
        _ResServices.getAllLocalisation(widget.residenceSelected);
  }

  void _updateFilters() {
    widget.onFilterUpdate(
      locationElement: _selectedEmplacement,
      type: labelsType,
      dateFrom: _dateFromController.text,
      dateTo: _dateToController.text,
      statut: _selectedStatut,
    );
  }

  void _updateShowfilter() {
    widget.updateShowFilter(
        showFilter: _showFilter); // Utilisation corrigée ici
  }

  @override
  Widget build(BuildContext context) {
    List<List<String>> declarationType = _typeList.typeDeclaration();
    final Color color = Theme.of(context).primaryColor;
    final double width = MediaQuery.of(context).size.width;
    double sizeDate = width / 2.2;

    return Container(
      width: width,
      color: Colors.white,
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FutureBuilder<List<Map<String, String>>>(
                future: _allLocationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // ⚠️ Mise à jour ici : List<Map<String, String>>
                    List<Map<String, String>> items = snapshot.data ?? [];

                    return MyMultiSelectedDropDown(
                      fontSize: SizeFont.para.size,
                      myKey: _multiSelectKey,
                      width: sizeDate,
                      label: "Localisation",
                      color: color,
                      // ⚠️ Ici on prend uniquement les labels
                      items: items
                          .map((item) => MultiSelectItem<String?>(
                              item["label"], item["label"]!))
                          .toList(),
                      onConfirm: (values) {
                        setState(() {
                          _selectedEmplacement = values
                              .where((element) => element != null)
                              .map((element) => element!)
                              .toList();

                          // Si tu veux aussi récupérer les `id`, tu peux ici :
                          List<String> selectedIds = items
                              .where((item) => values.contains(item["label"]))
                              .map((item) => item["id"]!)
                              .toList();

                          // Tu peux les stocker si tu veux (ajoute une variable `List<String>` par ex.)
                          _updateFilters();
                        });
                      },
                      onTap: (item) {
                        setState(() {
                          _selectedEmplacement.remove(item);
                        });
                      },
                    );
                  }
                },
              ),
              MyMultiSelectedDropDown(
                fontSize: SizeFont.para.size,
                myKey: _multiTypeKey,
                width: sizeDate,
                label: "Type",
                color: color,
                items: declarationType
                    .map((e) => MultiSelectItem<String?>(e[0], e[0]))
                    .take(3)
                    .toList(),
                onConfirm: (values) {
                  setState(() {
                    labelsType = values
                        .where((element) => element != null)
                        .map((element) => declarationType.firstWhere(
                              (type) => type[0] == element,
                              orElse: () => ["", ""],
                            )[1])
                        .take(3)
                        .toList();
                    _updateFilters();
                  });
                },
                onTap: (item) {
                  setState(() {
                    labelsType.removeWhere((element) =>
                        declarationType.firstWhere(
                          (type) => type[1] == element,
                          orElse: () => ["", ""],
                        )[0] ==
                        item);
                  });
                },
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  width: sizeDate,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: _dateFromController,
                    decoration: InputDecoration(
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today, size: 14),
                      suffixIcon: const Icon(Icons.arrow_drop_down, size: 23),
                      label: MyTextStyle.lotDesc(
                          "De", SizeFont.para.size, FontStyle.normal),
                      focusColor: color,
                    ),
                    readOnly: true,
                    onTap: () {
                      _selectDate("dateFrom");
                    },
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 50,
                  width: sizeDate,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: _dateToController,
                    decoration: InputDecoration(
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today, size: 14),
                      suffixIcon: const Icon(Icons.arrow_drop_down, size: 23),
                      label: MyTextStyle.lotDesc(
                          "à", SizeFont.para.size, FontStyle.normal),
                      focusColor: color,
                    ),
                    readOnly: true,
                    onTap: () {
                      _selectDate("dateTo");
                    },
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              MyMultiSelectedDropDown(
                fontSize: SizeFont.para.size,
                myKey: _multiStatutKey,
                width: sizeDate,
                label: "Statut",
                color: color,
                items: listStatu
                    .map((item) => MultiSelectItem<String?>(item, item))
                    .toList(),
                onConfirm: (values) {
                  setState(() {
                    _selectedStatut = values
                        .where((element) => element != null)
                        .map((element) => element!)
                        .toList();
                    _updateFilters();
                  });
                },
                onTap: (item) {
                  setState(() {
                    _selectedStatut.remove(item);
                  });
                },
              ),
              SizedBox(
                width: sizeDate,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedEmplacement = [];
                      labelsType = [];
                      _dateFromController.clear();
                      _dateToController.clear();
                      _selectedStatut = [];
                      _showFilter = !_showFilter;
                      _updateFilters();
                      _updateShowfilter(); // Appel de la mise à jour du filtre d'affichage
                    });
                  },
                  child: MyTextStyle.lotName("Réinitialiser les filtres",
                      Colors.black38, SizeFont.h3.size),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(String choice) async {
    DateTime today = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2022),
      lastDate: today,
    );

    setState(() {
      if (choice == "dateFrom") {
        _dateFromController.text = picked.toString().split(" ")[0];
      } else {
        _dateToController.text = picked.toString().split(" ")[0];
      }
      _updateFilters();
    });
  }
}
