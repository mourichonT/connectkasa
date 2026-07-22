"""
Script one-shot : pose rétroactivement previousEventId/reporte sur les
interventions reprogrammées via la page de partage AVANT le déploiement de
ce lien (reschedule_shared_intervention posait déjà event.previousEventDate
sur la nouvelle intervention, mais pas encore previousEventId/reporte).

Repère, pour chaque residences/{id}/posts de type "events" ayant
event.previousEventDate mais pas encore previousEventId, l'ancienne
intervention correspondante dans la même résidence (même type "events",
event.eventDate == event.previousEventDate de la nouvelle) : pose
previousEventId sur la nouvelle et reporte=true sur l'ancienne.

Ambiguïté (0 ou plusieurs candidats trouvés) : ignoré et signalé, pas de
correction automatique risquée.

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python backfill_reschedule_links.py --dry-run
    python backfill_reschedule_links.py
"""
import sys

import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()
DRY_RUN = "--dry-run" in sys.argv


def backfill():
    linked = 0
    ambiguous = 0
    skipped = 0

    for residence_doc in db.collection("residences").stream():
        residence_id = residence_doc.id
        posts_ref = db.collection("residences").document(residence_id).collection("posts")

        for post_doc in posts_ref.where("type", "==", "events").stream():
            data = post_doc.to_dict() or {}
            if data.get("previousEventId"):
                continue
            event = data.get("event") or {}
            previous_event_date = event.get("previousEventDate")
            if not previous_event_date:
                skipped += 1
                continue

            candidates = [
                d for d in posts_ref.where("type", "==", "events")
                .where("event.eventDate", "==", previous_event_date)
                .stream()
                if d.id != post_doc.id
            ]

            if len(candidates) != 1:
                ambiguous += 1
                print(
                    f"  [ambigu] residences/{residence_id}/posts/{post_doc.id} : "
                    f"{len(candidates)} candidat(s) trouvé(s) pour previousEventDate={previous_event_date}"
                )
                continue

            old_post = candidates[0]
            print(
                f"  residences/{residence_id}/posts/{old_post.id} (ancienne) "
                f"<- residences/{residence_id}/posts/{post_doc.id} (nouvelle)"
            )
            if not DRY_RUN:
                post_doc.reference.update({"previousEventId": old_post.id})
                old_post.reference.update({"reporte": True})
            linked += 1

    print(f"\n{'[DRY RUN] ' if DRY_RUN else ''}Résumé :")
    print(f"  paires liées   : {linked}")
    print(f"  ambigües       : {ambiguous}")
    print(f"  sans previousEventDate (déjà à jour ou jamais reprogrammé) : {skipped}")
    if DRY_RUN:
        print("\n(dry-run : aucune écriture effectuée)")


backfill()
