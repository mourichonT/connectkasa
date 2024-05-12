import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/event.dart';

class DatabasesEventsServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<Event>> getEventFromResidence(String uid, String doc) async {
    List<Event> events = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(doc)
          .collection("events")
          .orderBy('date', descending: true)
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        events.add(Event.fromJson(docSnapshot.data()));
      }
    } catch (e) {
      print("Error completing in getEventFromResidence: $e");
    }
    return events;
  }
}
