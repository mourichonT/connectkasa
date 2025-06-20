import 'package:flutter/material.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';

class AgencySearchResultList extends StatelessWidget {
  final bool isSearching;
  final List<Agency> searchResults;
  final void Function(Agency) onSelect;

  const AgencySearchResultList({
    Key? key,
    required this.isSearching,
    required this.searchResults,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      );
    } else if (searchResults.isNotEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        child: ListView.builder(
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final agency = searchResults[index];
            return ListTile(
              title: Text(agency.name),
              onTap: () => onSelect(agency),
            );
          },
        ),
      );
    } else {
      return const SizedBox.shrink(); // Aucun résultat ni chargement
    }
  }
}
