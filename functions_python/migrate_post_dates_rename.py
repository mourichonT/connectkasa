"""
Script one-shot : renomme les clés du sous-objet "dates" (déjà en place
depuis migrate_post_dates_field.py) - "timeStamp" -> "creationDate" et
"dateClosed" -> "closedDate". Post.fromMap() sait déjà relire les deux noms
(fallback), donc ce script n'est pas strictement nécessaire au
fonctionnement de l'app, mais aligne les documents déjà migrés sur le
nouveau nom pour ne pas faire cohabiter indéfiniment les deux écritures.

Ne touche que les documents ayant déjà un sous-objet "dates" (ceux migrés
par migrate_post_dates_field.py) - les documents encore au format à plat
("timeStamp"/"dateClosed" hors de "dates") seront directement écrits au bon
nom la prochaine fois qu'ils seront modifiés (toMap()/toUpdateMap() écrivent
déjà "creationDate"/"closedDate"), ou repris par
migrate_post_dates_field.py s'il est relancé.

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_post_dates_rename.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

RENAMES = {
    "timeStamp": "creationDate",
    "dateClosed": "closedDate",
}


def migrate_collection_group(name):
    docs = list(db.collection_group(name).stream())
    migrated = 0
    skipped = 0

    batch = db.batch()
    pending = 0

    for doc in docs:
        data = doc.to_dict()
        dates = data.get("dates")

        if not isinstance(dates, dict) or not any(old in dates for old in RENAMES):
            skipped += 1
            continue

        new_dates = dict(dates)
        for old_key, new_key in RENAMES.items():
            if old_key in new_dates:
                new_dates[new_key] = new_dates.pop(old_key)

        batch.update(doc.reference, {"dates": new_dates})
        pending += 1
        migrated += 1

        if pending >= 400:
            batch.commit()
            batch = db.batch()
            pending = 0

    if pending > 0:
        batch.commit()

    print(f"[{name}] {migrated} document(s) migré(s), {skipped} déjà à jour.")


migrate_collection_group("posts")
migrate_collection_group("signalements")
