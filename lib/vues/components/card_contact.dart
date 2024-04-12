import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class CardContact extends StatelessWidget {
  final Lot? selectedlot;

  CardContact(this.selectedlot);

  Future<void> _fetchAgency() async {}

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              height: 80,
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  )),
              child: Column(children: [
                Text(
                  'Pecoul Immobilier',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                )
              ]),
            ),
          ),
          Positioned(
            top: 90,
            left: 5,
            right: 5,
            child: Container(
              padding: EdgeInsets.all(16),
              height: 120,
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Column(children: [
                Text(
                  'adresse',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                )
              ]),
            ),
          )
        ],
      ),
    );
  }
}
