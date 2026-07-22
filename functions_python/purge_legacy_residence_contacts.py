"""
Script one-shot : supprime les documents résidus de l'ancienne architecture
contacts (residences/{id}/contacts/{contactId}), remplacée par la collection
racine contacts/{id} + residences/{id}.contactRefs (cf. firestore.rules,
migrate_contacts_to_root.py, migrate_contact_refs_to_residences.py).

Ces documents ont déjà été copiés vers contacts/{id} par
migrate_contacts_to_root.py, qui les avait volontairement laissés en place
("nettoyage manuel ultérieur une fois confiance acquise"). Plus aucun code
(app ou backoffice) ne les lit/écrit, et la règle Firestore correspondante a
été retirée (residences/{id}/contacts/{id} est désormais deny par défaut) :
ce script fait ce nettoyage manuel.

Ne touche à rien d'autre que cette sous-collection précise - ne supprime pas
les résidences elles-mêmes, ni la collection racine "contacts".

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python purge_legacy_residence_contacts.py [--dry-run]
"""
import sys

import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()
DRY_RUN = "--dry-run" in sys.argv


def purge():
    deleted = 0
    residences_touched = 0

    batch = db.batch()
    pending = 0

    def commit_if_full():
        nonlocal batch, pending
        if pending >= 400:
            if not DRY_RUN:
                batch.commit()
            batch = db.batch()
            pending = 0

    for residence_doc in db.collection("residences").stream():
        legacy_contacts = list(residence_doc.reference.collection("contacts").stream())
        if not legacy_contacts:
            continue

        residences_touched += 1
        for legacy_contact_doc in legacy_contacts:
            print(f"Suppression : residences/{residence_doc.id}/contacts/{legacy_contact_doc.id}")
            batch.delete(legacy_contact_doc.reference)
            pending += 1
            deleted += 1
            commit_if_full()

    if pending > 0 and not DRY_RUN:
        batch.commit()

    print(f"\n{deleted} document(s) supprimé(s) dans {residences_touched} résidence(s).")
    if DRY_RUN:
        print("(dry-run : aucune suppression effectuée)")


purge()
