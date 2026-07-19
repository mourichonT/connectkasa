"""
Backfill one-shot : pose termine=true sur les interventions (posts/{id}.type
== "events") qui ont déjà un compte-rendu (posts/{id}.type == "rapport",
linkedEventId) soumis avant que create_shared_rapport ne pose ce champ lui
aussi (ajouté après coup) - sans ce backfill, ces interventions resteraient
affichées comme non terminées malgré un compte-rendu déjà reçu.

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python backfill_termine_from_rapports.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

updated = 0
for res_doc in db.collection("residences").stream():
    residence_id = res_doc.id
    posts_ref = db.collection("residences").document(residence_id).collection("posts")
    for rapport_doc in posts_ref.where("type", "==", "rapport").stream():
        linked_event_id = (rapport_doc.to_dict() or {}).get("linkedEventId")
        if not linked_event_id:
            continue
        event_ref = posts_ref.document(linked_event_id)
        event_snap = event_ref.get()
        if not event_snap.exists or (event_snap.to_dict() or {}).get("termine") is True:
            continue
        event_ref.update({"termine": True})
        updated += 1
        print(f"residences/{residence_id}/posts/{linked_event_id}.termine = True")

print(f"\n{updated} intervention(s) mise(s) à jour.")
