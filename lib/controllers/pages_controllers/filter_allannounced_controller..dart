import 'package:flutter/material.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/my_multiselected_dropdown.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';

typedef FilterCallback = void Function(
    {required List<String?> categorie,
    required String dateFrom,
    required String dateTo,
    required int priceMin,
    required int priceMax});

class FilterAllAnnouncedController extends StatefulWidget {
  final String residenceSelected;
  final String uid;
  final FilterCallback onFilterUpdate;

  FilterAllAnnouncedController({
    super.key,
    required this.residenceSelected,
    required this.uid,
    required this.onFilterUpdate,
  });

  @override
  State<StatefulWidget> createState() => FilterAllAnnouncedControllerState();
}

class FilterAllAnnouncedControllerState
    extends State<FilterAllAnnouncedController> {
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final DataBasesPostServices _databaseServices = DataBasesPostServices();

  int _lowerValue = 0;
  int _upperValue = 0;

  late List<Post> annoncesTrouvees;

  Post? announceSelected;
  final TypeList _typeList = TypeList();
  final GlobalKey<FormFieldState> _multiTypeKey = GlobalKey<FormFieldState>();
  List<String?> labelsCategorie = [];
  bool visible = false;

  @override
  void initState() {
    super.initState();
    annoncesTrouvees = [];
    _fetchMinMaxPrices();
  }

  void _updateFilters() {
    widget.onFilterUpdate(
      categorie: labelsCategorie,
      dateFrom: _dateFromController.text,
      dateTo: _dateToController.text,
      priceMin: _lowerValue,
      priceMax: _upperValue,
    );
  }

  void _fetchMinMaxPrices() async {
    var prices =
        await _databaseServices.getMinMaxPrices(widget.residenceSelected);
    setState(() {
      _lowerValue = prices['priceMin']!;
      _upperValue = prices['priceMax']!;
      print(_upperValue);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> categories = _typeList.categoryAnnonce();
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
              MyMultiSelectedDropDown(
                myKey: _multiTypeKey,
                width: sizeDate,
                label: "Catégorie",
                color: color,
                items: categories
                    .map((item) => MultiSelectItem<String?>(item, item))
                    .toList(),
                onConfirm: (values) {
                  setState(() {
                    labelsCategorie = values
                        .where((element) => element != null)
                        .map((element) => element!)
                        .toList();
                    _updateFilters();
                  });
                },
                onTap: (item) {
                  setState(() {
                    labelsCategorie.remove(item);
                  });
                },
              ),
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
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.only(top: 10, left: 15, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyTextStyle.lotDesc("Prix", 13, FontStyle.normal),
                    Text("$_lowerValue - $_upperValue Kasas"),
                  ],
                ),
              ),
              RangeSlider(
                values:
                    RangeValues(_lowerValue.toDouble(), _upperValue.toDouble()),
                min: 0,
                max: _upperValue.toDouble() + 10,
                divisions: _upperValue + 10,
                labels: RangeLabels(
                  _lowerValue.toString(),
                  _upperValue.toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _lowerValue = values.start.round();
                    _upperValue = values.end.round();
                    _updateFilters();
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: sizeDate,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      labelsCategorie = [];
                      _dateFromController.clear();
                      _dateToController.clear();
                      _upperValue = _upperValue;
                      _lowerValue = _lowerValue;
                      _updateFilters();
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
