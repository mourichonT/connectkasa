import 'package:flutter/material.dart';

class MydocsPageView extends StatefulWidget {
  final String residenceSelected;
  final String uid;
  final Color colorStatut;

  const MydocsPageView(
      {super.key,
      required this.residenceSelected,
      required this.uid,
      required this.colorStatut});

  @override
  State<StatefulWidget> createState() => MydocsPageViewState();
}

class MydocsPageViewState extends State<MydocsPageView>
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
        child: Column(children: <Widget>[
          TabBar.secondary(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(
                text: 'Copropriétés',
              ),
              Tab(text: 'Personnels'),
            ],
          ),
        ]));
  }
}
