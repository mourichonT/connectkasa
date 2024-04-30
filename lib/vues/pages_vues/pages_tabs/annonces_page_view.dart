import 'package:flutter/material.dart';

class AnnoncesPageView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AnnoncesPageViewState();
}

class AnnoncesPageViewState extends State<AnnoncesPageView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          TabBar.secondary(
            controller: _tabController,
            tabs: <Widget>[
              const Tab(text: 'Annonces'),
              const Tab(text: 'Gérer')
            ],
          ),
          Expanded(
              child: TabBarView(controller: _tabController, children: <Widget>[
            Card(child: Text("Test")),
            Card(
              child: Text("Test2"),
            )
          ]))
        ],
      ),
    );
  }
}
