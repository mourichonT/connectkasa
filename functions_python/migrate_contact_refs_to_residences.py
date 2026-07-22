"""
Script one-shot : sort le rattachement résidence<->contact du document
contact partagé (contacts/{id}.residencesIds) vers la résidence
(residences/{id}.contactRefs, map {contactId: true}). Firestore n'a pas de
sécurité par champ : exposer residencesIds sur un document contact lisible
par plusieurs agences (Professionnel) faisait fuiter à chacune les
résidences gérées par les autres. En sortant le rattachement sur le document
résidence (déjà lisible par tout isSignedIn(), une résidence à la fois), il
n'y a plus de tableau cross-résidence à corréler - cf. firestore.rules,
bloc racine "contacts".

Pour chaque contacts/{id} ayant un residencesIds non vide : écrit
residences/{residenceId}.contactRefs.{id} = true pour chaque résidence
listée, puis supprime le champ residencesIds du contact (le code applicatif
n'en a plus besoin, cf. Contact.fromJson()/toJson() qui ne le lisent/écrivent
plus).

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé, APRÈS déploiement
des règles/du code (le rattachement doit déjà passer par contactRefs avant
la reprise, sinon les contacts semblent temporairement invisibles) :
    python migrate_contact_refs_to_residences.py [--dry-run]
"""
import sys

import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()
DRY_RUN = "--dry-run" in sys.argv


def migrate():
    contacts_ref = db.collection("contacts")
    migrated = 0
    skipped = 0
    link_writes = 0

    batch = db.batch()
    pending = 0

    def commit_if_full():
        nonlocal batch, pending
        if pending >= 400:
            if not DRY_RUN:
                batch.commit()
            batch = db.batch()
            pending = 0

    for contact_doc in contacts_ref.stream():
        data = contact_doc.to_dict() or {}
        residence_ids = data.get("residencesIds") or []

        if not residence_ids:
            skipped += 1
            continue

        for residence_id in residence_ids:
            residence_ref = db.collection("residences").document(residence_id)
            batch.update(residence_ref, {f"contactRefs.{contact_doc.id}": True})
            pending += 1
            link_writes += 1
            commit_if_full()
            print(f"Lien : residences/{residence_id}.contactRefs.{contact_doc.id} = true")

        batch.update(contact_doc.reference, {"residencesIds": firestore.DELETE_FIELD})
        pending += 1
        migrated += 1
        commit_if_full()

    if pending > 0 and not DRY_RUN:
        batch.commit()

    print(f"\n{migrated} contact(s) migré(s) ({link_writes} lien(s) résidence créé(s)), "
          f"{skipped} déjà sans residencesIds.")
    if DRY_RUN:
        print("(dry-run : aucune écriture effectuée)")


migrate()
