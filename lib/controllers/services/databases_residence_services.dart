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
          Residence.fromJson(doc.data()! as Map<String, dynamic>);

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

  Future<Residence> getResidenceByRef(String residenceId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception("Résidence non trouvée pour l'id $residenceId");
      }

      final residence =
          await Residence.fromFirestoreWithStructures(docSnapshot, null);
      print(residence.structures);
      return residence;
    } catch (e) {
      print("Une erreur s'est produite : $e");
      // Gérer l’erreur comme tu veux, ici on lance une exception
      rethrow;
    }
  }

  Future<bool> updateResidence(
      String refResidence, Map<String, dynamic> updatedData) async {
    try {
      DocumentReference<Map<String, dynamic>> docRef =
          FirebaseFirestore.instance.collection("Residence").doc(refResidence);

      DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

      if (snapshot.exists) {
        // Mise à jour des champs du document
        await docRef.update(updatedData);
        print("Résidence mise à jour avec succès.");
        return true;
      } else {
        print("La résidence avec la référence '$refResidence' n'existe pas.");
        return false;
      }
    } catch (e) {
      print("Erreur lors de la mise à jour de la résidence : $e");
      return false;
    }
  }

  Future<bool> updateField(String refResidence, String field, dynamic value) {
    return updateResidence(refResidence, {field: value});
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
        StructureResidence structure =
            StructureResidence.fromJson(data, doc.id);

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
        return StructureResidence.fromJson(data, doc.id);
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
        structures.add(
            StructureResidence.fromJson(docSnapshot.data(), docSnapshot.id));
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

  Future<void> addContact(String residenceId, Contact contact) async {
    try {
      final docRef = await db
          .collection("Residence")
          .doc(residenceId)
          .collection("contacts")
          .add(contact.toJson());

      // On récupère le doc.id généré automatiquement par Firestore
      contact.id = docRef.id;

      // (Optionnel) On le met à jour dans Firestore si tu veux que l'ID apparaisse aussi dans les données du document
      await docRef.update({'id': contact.id});

      print("Contact ajouté avec succès avec ID : ${contact.id}");
    } catch (e) {
      print("Erreur lors de l'ajout du contact : $e");
    }
  }

  Future<void> updateContact(String residenceId, Contact contact) async {
    try {
      if (contact.id!.isEmpty) {
        throw Exception("L'identifiant du contact est manquant.");
      }

      await db
          .collection("Residence")
          .doc(residenceId)
          .collection("contacts")
          .doc(contact.id)
          .update(contact.toJson());

      print("Contact mis à jour avec succès : ${contact.id}");
    } catch (e) {
      print("Erreur lors de la mise à jour du contact : $e");
    }
  }

  // Suppression d'un contact par son document ID dans la sous-collection "contacts"
  Future<void> removeContact(String residenceId, String contactDocId) async {
    try {
      await db
          .collection("Residence")
          .doc(residenceId)
          .collection("contacts")
          .doc(contactDocId)
          .delete();
      print("Contact supprimé avec succès");
    } catch (e) {
      print("Erreur lors de la suppression du contact : $e");
    }
  }

  /// Enregistre une structure dans la sous-collection "structure" d'une résidence.
  /// Si la structure n'a pas d'ID, elle est ajoutée. Sinon, elle est mise à jour.
  Future<void> saveStructure(
      String residenceId, StructureResidence structure) async {
    try {
      final collectionRef =
          db.collection("Residence").doc(residenceId).collection("structure");

      if (structure.id == null || structure.id!.isEmpty) {
        // Nouvelle structure : ajouter un nouveau document
        final docRef = await collectionRef.add(structure.toJson());
        // L'ID du document généré par Firestore est maintenant l'ID de notre objet
        structure.id = docRef.id;
        print(
            "Nouvelle structure ajoutée avec succès avec l'ID : ${structure.id}");
      } else {
        // Structure existante : mettre à jour le document en utilisant son ID existant
        await collectionRef.doc(structure.id).update(structure.toJson());
        print("Structure mise à jour avec succès : ${structure.id}");
      }
    } catch (e) {
      print("Erreur lors de l'enregistrement de la structure : $e");
    }
  }

  Future<void> removeStructure(String residenceId, String structureId) async {
    try {
      await db
          .collection("Residence")
          .doc(residenceId)
          .collection("structure")
          .doc(structureId)
          .delete();
      print("Sutructure supprimé avec succès");
    } catch (e) {
      print("Erreur lors de la suppression de la structure : $e");
    }
  }
}
