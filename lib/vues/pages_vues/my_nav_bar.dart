import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/controllers/services/authentification_service.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/vues/pages_vues/home_view.dart';
import 'package:connect_kasa/vues/components/my_bottomnavbar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/pages_models/lot.dart';
import '../../controllers/features/my_tab_bar_controller.dart';
import '../components/select_lot_component.dart';
import '../components/lot_bottom_sheet.dart';
import '../../controllers/features/my_texts_styles.dart';

class MyNavBar extends StatefulWidget {
  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  final LoadPreferedData _loadPreferedData = LoadPreferedData();
  final MyTabBarController tabController = MyTabBarController();
  Lot? lot;
  //List<Lot> lots = [];
  // DatasLots datasLots = DatasLots();

//final DataBasesServices _databaseServices = DataBasesServices();
//late Future<List<Lot?>> _lotByUser;

  double pad = 0;
  Lot? preferedLot;
  AuthentificationService authService = AuthentificationService();

  @override
  void initState() {
    super.initState();
    // _lotByUser = _databaseServices.getLotByIduser2(preferedLot!.idProprietaire);
    //lots = datasLots.listLot();
    _loadPreferedLot();
  }

  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = tabController.iconTabBar.listIcons();
    final List<Tab> tabs = icons.asMap().entries.map((entry) {
      IconData icon = entry.value;
      return Tab(
        icon: Icon(
          icon,
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.yellow,
          elevation: 20,
          /* actions: <Widget>[
            IconButton(
              icon: MyTextStyle.IconDrawer(
                  context, Icons.menu, EdgeInsets.only(top: pad)),
              tooltip: 'Show Snackbar',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This is a snackbar')));
              },
            ),
          ],*/
          title: MyTextStyle.logo(
              context, "connectKasa", EdgeInsets.only(top: pad)),
          flexibleSpace: Container(
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
                color: Colors.white),
          ),
          bottom: PreferredSize(
            key: UniqueKey(),
            preferredSize: Size.fromHeight(kToolbarHeight + kToolbarHeight),
            child: Column(
              children: [
                tabController.tabBar(tabs),
                InkWell(
                    child: SelectLotComponent(),
                    onTap: () {
                      // _loadPreferedLot(preferedLot);
                      _showLotBottomSheet(context);
                    })
              ],
            ),
          )),
      body: preferedLot != null
          ? Homeview(
              key: UniqueKey(),
              residenceSelected: preferedLot!.residenceId,
            )
          : CircularProgressIndicator(),
      endDrawer: Drawer(
        child: Column(children: [
          SizedBox(
            height: 500,
          ),
          ElevatedButton(
              onPressed: () async {
                UserCredential user = await authService.signInWithGoogle();
                if (user.user != null && user.user!.uid != "") {
                  // Ton traitement pour stocker l'User dans Firebase
                }
              },
              child: const Text("Google Auth"))
        ]),
      ),
      bottomNavigationBar: MyBottomNavBarView(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
          height: 65,
          width: 65,
          child: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.background,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PostFormController()));
              },
              child: Icon(
                Icons.notifications_active,
                size: 30,
                color: Theme.of(context).primaryColor,
              ),
              shape:
                  CircleBorder(), // Utilisez CircleBorder pour définir la forme du bouton
              materialTapTargetSize: MaterialTapTargetSize.padded)),
    );
  }

  Future<void> _loadPreferedLot() async {
    preferedLot = await _loadPreferedData.loadPreferedLot(preferedLot);
    setState(() {});
  }

  void _showLotBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return LotBottomSheet(
            selectedLot: preferedLot,
            onRefresh: () {
              _loadPreferedLot();
            },
          );
        });
  }
}
