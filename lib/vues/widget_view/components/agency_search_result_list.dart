import 'package:flutter/material.dart';
import 'package:konodal/models/pages_models/agency.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class AgencySearchResultList extends StatelessWidget {
  final bool isSearching;
  final List<Agency> searchResults;
  final void Function(Agency) onSelect;

  const AgencySearchResultList({
    super.key,
    required this.isSearching,
    required this.searchResults,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: AppLoader(),
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
              title: Text(
                  agency.syndic?.mail.isNotEmpty == true
                      ? agency.syndic!.mail
                      : agency.name),
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
