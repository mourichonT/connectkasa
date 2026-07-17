"""
Script one-shot : migre residences/*/contacts/* vers la collection racine
contacts/{id}, avec residencesIds: [resId d'origine], nameNormalized (clé de
correspondance insensible à la casse utilisée par manage_contact.dart pour
la détection de doublons - "Servimmo" == "servimmo"), isApproved: True
(contacts déjà en production sous l'ancien système, jamais soumis à
validation avant ce champ - grandfathered, pas de revue rétroactive
imposée), et likelyDuplicateIds (doublons potentiels entre résidences
DIFFÉRENTES partageant le même nameNormalized - purement informatif, JAMAIS
fusionné automatiquement, à traiter manuellement plus tard côté backoffice).

Copie 1:1 (id racine auto-généré, PAS l'ancien id résidence-scopé - évite
toute collision). Les documents source residences/*/contacts/* ne sont PAS
supprimés par ce script (nettoyage manuel ultérieur une fois confiance
acquise sur la nouvelle collection).

Script NON IDEMPOTENT (ids auto-générés à chaque exécution) : ne jamais
relancer sans avoir purgé la collection contacts racine au préalable si un
ré-run est nécessaire.

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_contacts_to_root.py [--dry-run]
"""
import sys

import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()
DRY_RUN = "--dry-run" in sys.argv


def normalize_name(name):
    return (name or "").strip().lower()


def migrate():
    contacts_root = db.collection("contacts")
    by_normalized_name = {}  # nameNormalized -> [(new_id, source_residence_id), ...]
    created = 0

    for res_doc in db.collection("residences").stream():
        for old_contact_doc in res_doc.reference.collection("contacts").stream():
            data = old_contact_doc.to_dict() or {}
            name_normalized = normalize_name(data.get("name"))
            new_doc_ref = contacts_root.document()
            new_data = {
                **data,
                "id": new_doc_ref.id,
                "residencesIds": [res_doc.id],
                "nameNormalized": name_normalized,
                "isApproved": True,
                "likelyDuplicateIds": [],  # rempli a l'etape 2 ci-dessous
            }
            if not DRY_RUN:
                new_doc_ref.set(new_data)
            created += 1
            by_normalized_name.setdefault(name_normalized, []).append(
                (new_doc_ref.id, res_doc.id))
            print(f"Copie : residences/{res_doc.id}/contacts/{old_contact_doc.id} "
                  f"-> contacts/{new_doc_ref.id}")

    # Etape 2 : detection de doublons - meme nameNormalized, residences
    # SOURCE differentes -> flag symetrique likelyDuplicateIds.
    duplicate_groups = 0
    for name_normalized, entries in by_normalized_name.items():
        distinct_residences = {res_id for _, res_id in entries}
        if len(distinct_residences) < 2:
            continue  # homonymie dans une seule residence : pas un doublon inter-residence
        duplicate_groups += 1
        ids = [new_id for new_id, _ in entries]
        for new_id, _ in entries:
            other_ids = [i for i in ids if i != new_id]
            if not DRY_RUN:
                contacts_root.document(new_id).update({"likelyDuplicateIds": other_ids})
            print(f"Doublon potentiel ({name_normalized}) : {new_id} <-> {other_ids}")

    print(f"\n{created} contact(s) copie(s), {duplicate_groups} groupe(s) de doublons potentiels.")
    if DRY_RUN:
        print("(dry-run : aucune ecriture effectuee)")


migrate()
