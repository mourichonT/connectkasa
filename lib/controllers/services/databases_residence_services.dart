import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/contact.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';

class DataBasesResidenceServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<Contact>> getEmergenciesContacts() async {
    List<Contact> contactsEmergencies = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await db.collection("contactsServices_fr").get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        contactsEmergencies.add(Contact.fromJson(docSnapshot.data()));
      }
    } catch (e) {
      print("impossible de récupérer les contacts d'urgence $e");
    }

    return contactsEmergencies;
  }

  Future<List<Contact>> getContactByResidence(String residence) async {
    List<Contact> contacts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(residence)
          .collection("contacts")
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        contacts.add(Contact.fromJson(docSnapshot.data()));
      }
      print("Successfully completed");
    } catch (e) {
      print("Error completing in getContactByResidence: $e");
    }
    return contacts;
  }

  Future<List<Residence>> rechercheFirestore(String saisie) async {
    List<Residence> residencesTrouvees = [];

    // Récupérer une référence à la collection
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection("Residence");

    // Effectuer la requête de recherche
    QuerySnapshot querySnapshot = await collectionReference.get();

    // Boucler à travers les documents
    for (var doc in querySnapshot.docs) {
      // Convertir les données en un objet Residence
      Residence residence =
          Residence.fromMap(doc.data()! as Map<String, dynamic>);

      // Vérifier si les champs requis contiennent la saisie
      if ((residence.name.toLowerCase().contains(saisie.toLowerCase())) ||
          (residence.street.toLowerCase().contains(saisie.toLowerCase())) ||
          (residence.numero.toLowerCase().contains(saisie.toLowerCase())) ||
          (residence.city.toLowerCase().contains(saisie.toLowerCase())) ||
          (residence.zipCode.toLowerCase().contains(saisie.toLowerCase()))) {
        // Ajouter la résidence trouvée à la liste des résidences trouvées
        residencesTrouvees.add(residence);
      }
    }

    return residencesTrouvees;
  }

  // Future<List<Residence>> rechercheFirestore(String saisie) async {
  //   List<Residence> residences = [];
  //   // Récupérer une référence à la collection
  //   CollectionReference collectionReference =
  //       FirebaseFirestore.instance.collection("Residence");

  //   // Effectuer la requête de recherche
  //   QuerySnapshot querySnapshot = await collectionReference.get();

  //   // Boucler à travers les documents
  //   for (var doc in querySnapshot.docs) {
  //     // Vérifier si les données du document ne sont pas nulles et sont de type Map<String, dynamic>
  //     if (doc.data() != null && doc.data() is Map<String, dynamic>) {
  //       // Convertir les données en un Map<String, dynamic>
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

  //       // Vérifier si la clé "votre_recherche" existe dans les données
  //       if (data.containsValue(saisie)) {
  //         residences.add(Residence.fromJson(data));
  //         print("Document trouvé : ${doc.id}");
  //         print(
  //             "Champ correspondant : votre_recherche - Valeur : ${data[saisie]}");
  //         // Vous pouvez ajouter ici le traitement supplémentaire que vous souhaitez effectuer pour chaque document trouvé
  //       }
  //     }
  //   }
  //   return residences;
  // }
}