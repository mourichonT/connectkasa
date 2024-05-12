import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_events_services.dart';
import 'package:connect_kasa/models/pages_models/event.dart';
import 'package:flutter/material.dart';

Widget EventTile(String uid, String residenceSelected) {
  final DatabasesEventsServices _databaseService = DatabasesEventsServices();
  return FutureBuilder<List<Event>>(
    future: _databaseService.getEventFromResidence(uid, residenceSelected),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(); // Affichez un indicateur de chargement pendant le chargement des données
      } else if (snapshot.hasError) {
        return Text('Erreur: ${snapshot.error}');
      } else {
        if (snapshot.data!.isEmpty) {
          return Text("Aucun événement trouvé");
        } else {
          // Affichez vos événements récupérés
          return Column(
            children: snapshot.data!.map((event) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Card(
                  child: ListTile(
                    leading: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MyTextStyle.EventDateDay(event.date, 25),
                          MyTextStyle.EventDateMonth(event.date, 14),
                        ]),
                    title: Text(event.title),
                    subtitle: Text(event.description),
                    // Autres détails de l'événement
                  ),
                ),
              );
            }).toList(),
          );
        }
      }
    },
  );
}
