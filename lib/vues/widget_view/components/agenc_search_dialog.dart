import 'package:flutter/material.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/controllers/services/databases_agency_services.dart';

class AgencySearchDialog {
  static Future<Agency?> show(BuildContext context, String service) async {
    final TextEditingController searchController = TextEditingController();
    final DatabasesAgencyServices _agencyServices = DatabasesAgencyServices();
    List<Agency> dialogResults = [];
    bool isDialogSearching = false;

    return showDialog<Agency>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Rechercher une agence par email"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Entrez un email ou une partie",
                    ),
                    onChanged: (val) async {
                      if (val.isEmpty) {
                        setState(() {
                          dialogResults.clear();
                          isDialogSearching = false;
                        });
                      } else {
                        setState(() {
                          isDialogSearching = true;
                        });

                        final results = await _agencyServices
                            .searchAgencyByEmail(service, val);

                        setState(() {
                          dialogResults = results;
                          isDialogSearching = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  if (isDialogSearching)
                    const CircularProgressIndicator()
                  else if (dialogResults.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: dialogResults.length,
                        itemBuilder: (context, index) {
                          final agency = dialogResults[index];
                          return ListTile(
                            title: Text(agency.name),
                            subtitle: Text(agency.syndic!.mail ?? ""),
                            onTap: () {
                              Navigator.of(context).pop(agency);
                            },
                          );
                        },
                      ),
                    )
                  else if (searchController.text.isNotEmpty)
                    const Text("Aucune agence trouvée"),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Fermer"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
