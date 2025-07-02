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

  /// Récupère tous les documents de la sous-collection "structure" pour une résidence donnée.
  /// Prend l'ID de la résidence en paramètre.
  /// Retourne une liste d'objets StructureResidence.
  Future<List<StructureResidence>> getStructuresByResidence(
      String residenceId) async {
    List<StructureResidence> structures = [];
    try {
      // Accède à la sous-collection "structure" de la résidence spécifiée
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(residenceId)
          .collection("structure")
          .get();

      // Parcourt chaque document et le convertit en objet StructureResidence
      for (var docSnapshot in querySnapshot.docs) {
        structures.add(StructureResidence.fromJson(docSnapshot.data()));
      }

      // Trie la liste des structures
      structures.sort((a, b) {
        // Tri d'abord par la longueur du nom (du plus court au plus long)
        final lengthComparison = a.name.length.compareTo(b.name.length);
        if (lengthComparison != 0) {
          return lengthComparison;
        }
        // Si les longueurs sont égales, trie alphabétiquement par le nom
        return a.name.compareTo(b.name);
      });

      print(
          "Structures récupérées et triées avec succès pour la résidence $residenceId.");
    } catch (e) {
      print(
          "Erreur lors de la récupération et du tri des structures pour la résidence $residenceId: $e");
    }
    return structures;
  }

  Future<void> removeCsMember(String residenceId, String uidToRemove) async {
    try {
      await FirebaseFirestore.instance
          .collection('Residence')
          .doc(residenceId)
          .update({
        'csmembers': FieldValue.arrayRemove([uidToRemove])
      });

      print("UID $uidToRemove supprimé avec succès de csmembers.");
    } catch (e) {
      print("Erreur lors de la suppression de l'UID $uidToRemove : $e");
    }
  }

  Future<void> addCsMember(String residenceId, String uidToAdd) async {
    try {
      await FirebaseFirestore.instance
          .collection('Residence')
          .doc(residenceId)
          .update({
        'csmembers': FieldValue.arrayUnion([uidToAdd])
      });

      print("UID $uidToAdd ajouté avec succès à csmembers.");
    } catch (e) {
      print("Erreur lors de l'ajout de l'UID $uidToAdd : $e");
    }
  }
}
