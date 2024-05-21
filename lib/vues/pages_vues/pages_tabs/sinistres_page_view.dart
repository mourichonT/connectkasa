import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/pages_vues/sinistre_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class SinistrePageView extends StatefulWidget {
  String residenceSelected;
  String uid;
  String? argument1;
  String? argument2;

  SinistrePageView({
    super.key,
    required this.residenceSelected,
    required this.uid,
    this.argument1,
    this.argument2,
  });

  @override
  State<StatefulWidget> createState() => SinistrePageViewState();
}

class SinistrePageViewState extends State<SinistrePageView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  final DataBasesResidenceServices _ResServices = DataBasesResidenceServices();
  late final TabController _tabController;
  late Future<List<Post>> _allPostsFuture;
  late Future<List<String>> _allLocationsFuture;
  bool _showFilters = false;
  bool _selectedTab = false;
  late Post post;
  String? _selectedDetails;
  String? selectedType;
  // String? selectedValue;
  final TypeList _typeList = TypeList();
  final _multiSelectKey = GlobalKey<FormFieldState>();
  final _multiStatutKey = GlobalKey<FormFieldState>();
  final _multiTypeKey = GlobalKey<FormFieldState>();
  List<String?> _selectedEmplacement = [];
  List<String?> _selectedStatut = [];
  List<String?> labelsType = [];
  //List<String?> typeValue = [];

  final List<String> listStatu = [
    "Validé",
    "En attente",
    "Refusé"
  ]; // Déclarez _selectedEmplacement comme List<String?>
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allPostsFuture = _databaseServices.getAllPosts(widget.residenceSelected);
    _tabController.addListener(_handleTabChange);
    _allLocationsFuture =
        _ResServices.getAllLocalisation(widget.residenceSelected);
    _selectedTab = _tabController.index == 0;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _selectedTab = _tabController.index == 0;
    });
  }

  void _updateFilters() {
    setState(() {
      _allPostsFuture = _databaseServices.getAllPostsWithFilters(
        doc: widget.residenceSelected,
        locationElement: _selectedEmplacement,
        type: labelsType,
        dateFrom: _dateFromController.text,
        dateTo: _dateToController.text,
        statut: _selectedStatut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    List<List<String>> declarationType = _typeList.typeDeclaration();
    initializeDateFormatting('fr_FR', null);

    final Color color = Theme.of(context).primaryColor;
    final double width = MediaQuery.of(context).size.width;
    double sizeDate = width / 2.2;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          TabBar.secondary(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Toutes'),
              Tab(text: 'Mes déclarations'),
            ],
          ),
          if (_showFilters && _selectedTab)
            Container(
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            List<String?> _items =
                                (snapshot.data ?? []).cast<String>();
                            return Expanded(
                              child: Container(
                                width: sizeDate,
                                child: MultiSelectBottomSheetField<String?>(
                                  isDismissible: true,
                                  key: _multiSelectKey,
                                  initialChildSize: 0.7,
                                  maxChildSize: 0.95,
                                  title: MyTextStyle.annonceDesc(
                                      "Recherche", 16, 1),
                                  buttonText: MyTextStyle.lotDesc(
                                    "Localisation",
                                    13,
                                    FontStyle.normal,
                                  ),
                                  checkColor: Colors.white,
                                  selectedColor: color,
                                  items: _items
                                      .map((item) =>
                                          MultiSelectItem<String?>(item, item!))
                                      .toList(),
                                  searchable: true,
                                  buttonIcon: Icon(Icons.arrow_drop_down),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors
                                            .black12, // Changez la couleur ici
                                        width:
                                            0.5, // Ajustez l'épaisseur de la ligne si nécessaire
                                      ),
                                    ),
                                  ),
                                  onConfirm: (List<String?> values) {
                                    setState(() {
                                      _selectedEmplacement = values
                                          .where((element) => element != null)
                                          .map((element) =>
                                              element!) // Convertissez les éléments non nuls en non-optionnels
                                          .toList();
                                      _updateFilters();
                                    });
                                    _multiSelectKey.currentState?.validate();
                                  },
                                  chipDisplay: MultiSelectChipDisplay(
                                    height: 50,
                                    onTap: (item) {
                                      setState(() {
                                        _selectedEmplacement.remove(item);
                                      });
                                      _multiSelectKey.currentState!.validate();
                                    },
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      Container(
                        width: sizeDate,
                        child: MultiSelectBottomSheetField<String?>(
                          key: _multiTypeKey,
                          initialChildSize: 0.7,
                          maxChildSize: 0.95,
                          title: MyTextStyle.annonceDesc("Recherche", 16, 1),
                          buttonText: MyTextStyle.lotDesc(
                            "Type",
                            13,
                            FontStyle.normal,
                          ),
                          checkColor: Colors.white,
                          selectedColor: color,
                          items: declarationType
                              .map((e) => e.last)
                              .map((item) =>
                                  MultiSelectItem<String?>(item, item!))
                              .toList(),
                          searchable: true,
                          buttonIcon: Icon(
                            Icons.arrow_drop_down,
                            size: 24,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black12, // Changez la couleur ici
                                width:
                                    1, // Ajustez l'épaisseur de la ligne si nécessaire
                              ),
                            ),
                          ),
                          onConfirm: (List<String?> values) {
                            setState(() {
                              labelsType =
                                  declarationType.map((e) => e.last).toList();
                              //typeValue = declarationType.map((e) => e.last).toList();
                              labelsType = values
                                  .where((element) => element != null)
                                  .map((element) =>
                                      element!) // Convertissez les éléments non nuls en non-optionnels
                                  .toList();

                              _updateFilters();
                            });
                            _multiTypeKey.currentState?.validate();
                          },
                          chipDisplay: MultiSelectChipDisplay(
                            height: 50,
                            onTap: (item) {
                              setState(() {
                                labelsType.remove(item);
                              });
                              _multiTypeKey.currentState!.validate();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(left: 0),
                          height: 50,
                          width: sizeDate,
                          child: TextField(
                            textAlign: TextAlign.center,
                            controller: _dateFromController,
                            decoration: InputDecoration(
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors
                                        .black12), // Change to your desired color
                              ),
                              prefixIconConstraints:
                                  BoxConstraints(minWidth: 0, minHeight: 0),
                              suffixIconConstraints:
                                  BoxConstraints(minWidth: 0, minHeight: 0),
                              // filled: true,
                              prefixIcon: const Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                ),
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 1),
                                child: const Icon(
                                  Icons.arrow_drop_down,
                                  size: 23,
                                ),
                              ),
                              label: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: MyTextStyle.lotDesc(
                                  "Depuis",
                                  13,
                                  FontStyle.normal,
                                ),
                              ),
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
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors
                                        .black12), // Change to your desired color
                              ),
                              prefixIconConstraints:
                                  BoxConstraints(minWidth: 0, minHeight: 0),
                              suffixIconConstraints:
                                  BoxConstraints(minWidth: 0, minHeight: 0),
                              // filled: true,
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, right: 10),
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                ),
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(Icons.arrow_drop_down),
                              ),
                              label: MyTextStyle.lotDesc(
                                "Jusqu'à",
                                13,
                                FontStyle.normal,
                              ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: sizeDate,
                          child: MultiSelectBottomSheetField<String?>(
                            isDismissible: true,
                            key: _multiStatutKey,
                            initialChildSize: 0.7,
                            maxChildSize: 0.95,
                            title: MyTextStyle.annonceDesc("Recherche", 16, 1),
                            buttonText: MyTextStyle.lotDesc(
                              "Statut",
                              13,
                              FontStyle.normal,
                            ),
                            checkColor: Colors.white,
                            selectedColor: color,
                            items: listStatu
                                .map((item) =>
                                    MultiSelectItem<String?>(item, item))
                                .toList(),
                            searchable: true,
                            buttonIcon: Icon(Icons.arrow_drop_down),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      Colors.black12, // Changez la couleur ici
                                  width:
                                      1, // Ajustez l'épaisseur de la ligne si nécessaire
                                ),
                              ),
                            ),
                            onConfirm: (List<String?> values) {
                              setState(() {
                                _selectedStatut = values
                                    .where((element) => element != null)
                                    .map((element) =>
                                        element!) // Convertissez les éléments non nuls en non-optionnels
                                    .toList();
                                _updateFilters();
                              });
                              _multiSelectKey.currentState?.validate();
                            },
                            chipDisplay: MultiSelectChipDisplay(
                              height: 50,
                              onTap: (item) {
                                setState(() {
                                  _selectedStatut.remove(item);
                                });
                                _multiSelectKey.currentState!.validate();
                              },
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: sizeDate,
                        child: TextButton(
                            onPressed: () {
                              _selectedEmplacement = [];
                              labelsType = [];
                              _dateFromController.text = "";
                              _dateToController.text = "";
                              _selectedStatut = [];

                              _updateFilters();

                              _showFilters = !_showFilters;
                            },
                            child: MyTextStyle.lotName(
                                "Réinitialiser les filtres",
                                Colors.black38,
                                13)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          if (_selectedTab)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              child: Container(
                width: width,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    MyTextStyle.lotName(
                        "Ajouter des filtres", Colors.white, 14),
                  ],
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                FutureBuilder<List<Post>>(
                  future: _allPostsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      List<Post> allPosts = snapshot.data!;
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: allPosts.length,
                            itemBuilder: (context, index) {
                              post = allPosts[index];
                              return Column(
                                children: [
                                  if (post.user != widget.uid &&
                                          post.type == widget.argument1 ||
                                      post.user != widget.uid &&
                                          post.type == widget.argument2)
                                    SinistreTile(post, widget.residenceSelected,
                                        widget.uid, false),
                                ],
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(height: 5),
                          ),
                        ),
                      );
                    }
                  },
                ),
                FutureBuilder<List<Post>>(
                  future: _allPostsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      List<Post> allPosts = snapshot.data!;
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: allPosts.length,
                            itemBuilder: (context, index) {
                              Post post = allPosts[index];
                              return Column(
                                children: [
                                  if (post.user == widget.uid &&
                                          post.type == widget.argument1 ||
                                      post.user == widget.uid &&
                                          post.type == widget.argument2)
                                    SinistreTile(post, widget.residenceSelected,
                                        widget.uid, false),
                                ],
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(height: 5),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(String choice) async {
    DateTime today = DateTime.now();
    // Locale myLocale = Locale('fr', 'FR');
    DateTime nextYear = DateTime.utc(today.year + 1, today.month, today.day);
    DateTime? _picked = await showDatePicker(
        //   locale: myLocale,
        context: context,
        initialDate: today,
        firstDate: DateTime(2022),
        lastDate: today);

    if (_picked != null && choice == "dateFrom") {
      setState(() {
        _dateFromController.text = _picked.toString().split(" ")[0];
        _updateFilters();
      });
    } else {
      setState(() {
        _dateToController.text = _picked.toString().split(" ")[0];
        _updateFilters();
      });
    }
  }
}
