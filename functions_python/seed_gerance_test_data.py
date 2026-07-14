"""
Script one-shot : crée 3 documents gerances de test (2 syndics, 1 agence de
location) au format `services` + `address` uniformisé (même forme que
Residence/Agency : {street, complement, zipCode, city, codeQualite}).
À exécuter une seule fois, en local, avec les credentials admin.

Prérequis : télécharger une clé de service account depuis la console
Firebase (Paramètres du projet > Comptes de service > Générer une nouvelle
clé privée), l'enregistrer à côté de ce script sous le nom
"service-account.json" (jamais commité, déjà couvert par .gitignore via
key.properties/*.json si besoin de vérifier).

Exécution : depuis functions_python/, avec le venv activé :
    python seed_gerance_test_data.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

# ID de document auto-généré par Firestore (pas de chaîne choisie à la main) :
# évite tout risque de collision/doublon si le script est relancé ou si un
# vrai cabinet portait un jour le même nom.
GERANCE_DOCS = [
    # Syndic A : petite agence, contact uniquement au niveau service (pas
    # de mail direct par agent).
    {
        "name": "Cabinet Dupont",
        "address": {
            "street": "12 rue des Lilas",
            "complement": None,
            "zipCode": "75011",
            "city": "Paris",
            "codeQualite": "60",
        },
        "services": {
            "serviceSyndic": {
                "mail": "contact@cabinet-dupont.fr",
                "phone": "0140000001",
                "agents": [
                    {"name_agent": "Dupont", "surname_agent": "Bernard"},
                ],
            },
        },
    },
    # Syndic B : plus grosse agence, un agent a son propre mail direct en
    # plus du contact général du service.
    {
        "name": "Groupe Immo Martin",
        "address": {
            "street": "45 avenue Victor Hugo",
            "complement": None,
            "zipCode": "69003",
            "city": "Lyon",
            "codeQualite": "60",
        },
        "services": {
            "serviceSyndic": {
                "mail": "syndic@immo-martin.fr",
                "phone": "0472000002",
                "agents": [
                    {
                        "name_agent": "Martin",
                        "surname_agent": "Claire",
                        "mail": "claire.martin@immo-martin.fr",
                        "phone": "0472000003",
                    },
                    {"name_agent": "Petit", "surname_agent": "Julien"},
                ],
            },
        },
    },
    # Agence de location uniquement (aucun service syndic).
    {
        "name": "Agence Location Plus",
        "address": {
            "street": "8 boulevard Gambetta",
            "complement": None,
            "zipCode": "33000",
            "city": "Bordeaux",
            "codeQualite": "60",
        },
        "services": {
            "geranceLocative": {
                "mail": "location@location-plus.fr",
                "phone": "0556000004",
                "agents": [
                    {
                        "name_agent": "Lefevre",
                        "surname_agent": "Sophie",
                        "mail": "sophie.lefevre@location-plus.fr",
                        "phone": "0556000005",
                    },
                ],
            },
        },
    },
]

for data in GERANCE_DOCS:
    doc_ref = db.collection("gerances").document()  # ID auto-généré
    doc_ref.set(data)
    print(f"Créé : gerances/{doc_ref.id} ({data['name']}, {list(data['services'].keys())})")

print("\nTerminé. sync_gerance_contacts doit être déployée AVANT ce script "
      "pour que l'index gerances/{id}/contacts soit généré automatiquement.")
