import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/contact.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/models/pages_models/structure_residence.dart';

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

  Future<Residence> getResidenceByRef(String residence) async {
    Residence? res; // Initialiser res à null

    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection("Residence")
              .doc(residence)
              .get();

      if (documentSnapshot.exists) {
        // Si le document existe dans la base de données
        Map<String, dynamic> data = documentSnapshot
            .data()!; // Utilisation de l'opérateur de nullabilité pour indiquer que 'data' ne sera pas nul

        // Initialisez les propriétés de l'objet Residence en utilisant toutes les données récupérées
        res = Residence.fromJson(data);
        // Utilisez une méthode ou un constructeur pour initialiser l'objet Residence avec toutes les données
      } else {
        print("la fonction getResidenceByRef renvoie null");

        // Si le document n'existe pas, vous pouvez choisir de renvoyer une valeur par défaut ou de gérer cela d'une autre manière selon votre logique métier
        // Ici, nous attribuons null à 'res' car le document n'existe pas
        res = null;
      }
    } catch (e) {
      // Gérez les erreurs éventuelles ici
      print("Une erreur s'est produite : $e");
      // Ici, vous pouvez choisir de renvoyer une valeur par défaut ou de gérer l'erreur d'une autre manière
      // Par exemple, attribuer null à 'res' en cas d'erreur
      res = null;
    }

    return res!;
  }

  // Future<List<String>> getAllLocalisation(String residence) async {
  //   List<String> allLocalisation = [];
  //   try {
  //     // Obtenez une référence au document spécifique dans la collection "Residence"
  //     DocumentReference documentReference =
  //         FirebaseFirestore.instance.collection("Residence").doc(residence);

  //     // Effectuer la requête de recherche
  //     DocumentSnapshot documentSnapshot = await documentReference.get();

  //     // Vérifiez si le document existe
  //     if (documentSnapshot.exists) {
  //       // Récupérez les données du document
  //       Map<String, dynamic> data =
  //           (documentSnapshot.data() as Map<String, dynamic>);

  //       // Vérifiez si le champ "localisation" existe et s'il est non nul
  //       if (data.containsKey("localistation") &&
  //           data["localistation"] != null) {
  //         // Récupérez la liste des localisations
  //         List<dynamic> localisations = data["localistation"];

  //         // Parcourir la liste et ajouter chaque localisation à la liste _allLocalisation
  //         for (var loc in localisations) {
  //           if (loc is String) {
  //             allLocalisation.add(loc);
  //           }
  //         }
  //       } else {
  //         print(
  //             "Le champ 'localisation' est manquant ou nul dans le document '$residence'");
  //       }
  //     } else {
  //       print(
  //           "Le document '$residence' n'existe pas dans la collection 'Residence'");
  //     }
  //   } catch (e) {
  //     // Gérer les erreurs ici, si nécessaire
  //     print("Une erreur s'est produite : $e");
  //   }
  //   return allLocalisation;
  // }

  Future<List<Map<String, String>>> getAllLocalisation(
      String residenceId) async {
    List<Map<String, String>> allLocalisation = [];

    try {
      CollectionReference structureRef = FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("structure");

      QuerySnapshot querySnapshot = await structureRef.get();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        StructureResidence structure = StructureResidence.fromJson(data);

        if (structure.name.isNotEmpty && structure.type.isNotEmpty) {
          allLocalisation.add({
            'id': doc.id,
            'label': "${structure.type} ${structure.name}",
          });
        }
      }

      // Supprimer les doublons
      allLocalisation =
          {for (var loc in allLocalisation) loc['label']!: loc}.values.toList();

      // Trier par longueur puis alphabétiquement
      allLocalisation.sort((a, b) {
        if (a['label']!.length != b['label']!.length) {
          return a['label']!.length.compareTo(b['label']!.length);
        }
        return a['label']!.compareTo(b['label']!);
      });
    } catch (e) {
      print("Erreur lors de la récupération des localisations : $e");
    }

    return allLocalisation;
  }

  Future<StructureResidence?> getDetailLocalisation(
      String residenceId, String locId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("structure")
          .doc(locId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return StructureResidence.fromJson(data);
      } else {
        print("Document $locId non trouvé dans la résidence $residenceId.");
        return null;
      }
    } catch (e) {
      print(
          "Erreur lors de la récupération des détails de la localisation : $e");
      return null;
    }
  }
}
