"""
Script one-shot : migre les documents Post existants vers le nouveau format
QUAL 1 (regroupement des 6 champs de style à plat - backgroundColor,
backgroundImage, fontColor, fontSize, fontWeight, fontStyle - dans un objet
unique "style"). Post.fromMap() sait déjà relire les deux formats (aucune
migration n'est strictement nécessaire pour le fonctionnement de l'app),
mais ce script aligne les données existantes sur le nouveau format pour ne
pas faire cohabiter indéfiniment les deux écritures en base.

Parcourt tous les documents des collections "post" (Residence/{id}/post/{id})
et "signalements" (Residence/{id}/post/{id}/signalements/{id}) via des
collection group queries, et pour chaque document possédant au moins un des
6 champs à plat : écrit le champ "style" imbriqué puis supprime les 6 champs
à plat.

Prérequis : service-account.json à côté de ce script (voir
seed_gerance_test_data.py pour la procédure de récupération).

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_post_style_field.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

LEGACY_STYLE_FIELDS = [
    "backgroundColor",
    "backgroundImage",
    "fontSize",
    "fontWeight",
    "fontColor",
    "fontStyle",
]


def migrate_collection_group(name):
    docs = list(db.collection_group(name).stream())
    migrated = 0
    skipped = 0

    batch = db.batch()
    pending = 0

    for doc in docs:
        data = doc.to_dict()

        if not any(field in data for field in LEGACY_STYLE_FIELDS):
            skipped += 1
            continue

        style = {field: data.get(field) for field in LEGACY_STYLE_FIELDS}
        update = {"style": style}
        update.update({field: firestore.DELETE_FIELD for field in LEGACY_STYLE_FIELDS})

        batch.update(doc.reference, update)
        pending += 1
        migrated += 1

        # Une batch Firestore est limitée à 500 opérations.
        if pending >= 400:
            batch.commit()
            batch = db.batch()
            pending = 0

    if pending > 0:
        batch.commit()

    print(f"[{name}] {migrated} document(s) migré(s), {skipped} déjà à jour.")


migrate_collection_group("post")
migrate_collection_group("signalements")
