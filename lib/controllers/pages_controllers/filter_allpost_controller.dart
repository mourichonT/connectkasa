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
  final ShowFilterCallback updateShowFilter; // Corrigé ici

  FilterAllPostController({
    super.key,
    required this.residenceSelected,
    required this.uid,
    required this.onFilterUpdate,
    required this.updateShowFilter, // Corrigé ici
  });

  @override
  State<StatefulWidget> createState() => FilterAllPostControllerState();
}

class FilterAllPostControllerState extends State<FilterAllPostController> {
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  final DataBasesResidenceServices _ResServices = DataBasesResidenceServices();
  late Future<List<String?>> _allLocationsFuture;
  late Post post;
  final TypeList _typeList = TypeList();
  final GlobalKey<FormFieldState> _multiSelectKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _multiStatutKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _multiTypeKey = GlobalKey<FormFieldState>();
  List<String?> _selectedEmplacement = [];
  List<String?> _selectedStatut = [];
  List<String?> labelsType = [];
  bool _showFilter = true;
  final List<String> listStatu = ["Validé", "En attente", "Refusé"];

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
              FutureBuilder<List<String?>>(
                future: _allLocationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<String?> _items =
                        (snapshot.data ?? []).cast<String?>();
                    return MyMultiSelectedDropDown(
                      myKey: _multiSelectKey,
                      width: sizeDate,
                      label: "Localisation",
                      color: color,
                      items: _items
                          .map((item) => MultiSelectItem<String?>(item, item!))
                          .toList(),
                      onConfirm: (values) {
                        setState(() {
                          _selectedEmplacement = values
                              .where((element) => element != null)
                              .map((element) => element!)
                              .toList();
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
                child: Container(
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
                      label: MyTextStyle.lotDesc("De", 13, FontStyle.normal),
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
                child: Container(
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
                      label: MyTextStyle.lotDesc("à", 13, FontStyle.normal),
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
            children: [
              MyMultiSelectedDropDown(
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
              Container(
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
                  child: MyTextStyle.lotName(
                      "Réinitialiser les filtres", Colors.black38, 13),
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
    DateTime? _picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2022),
      lastDate: today,
    );

    if (_picked != null) {
      setState(() {
        if (choice == "dateFrom") {
          _dateFromController.text = _picked.toString().split(" ")[0];
        } else {
          _dateToController.text = _picked.toString().split(" ")[0];
        }
        _updateFilters();
      });
    }
  }
}
