"""
Script one-shot : migre les documents Post existants vers le nouveau format
(regroupement des champs date à plat - timeStamp, declaredDate, dateClosed -
dans un objet unique "dates"). Post.fromMap() sait déjà relire les deux
formats (aucune migration n'est strictement nécessaire pour le
fonctionnement de l'app), mais tant que ce script n'a pas tourné, les
documents existants restent invisibles des requêtes triées/filtrées sur
"dates.timeStamp" (orderBy/where dans firestore_post_repository.dart) - ce
script aligne les données existantes sur le nouveau format pour ne pas faire
cohabiter indéfiniment les deux écritures en base. Même mécanique que
migrate_post_style_field.py (regroupement des champs de style), en corrigeant
au passage le nom de collection_group utilisé par ce script historique
("post" au singulier - erreur restée sans conséquence car la vraie
sous-collection est "posts" au pluriel, cf. firestore.rules et
firestore_post_repository.dart).

Parcourt tous les documents des collections "posts"
(Residence/{id}/posts/{id}) et "signalements"
(Residence/{id}/posts/{id}/signalements/{id}) via des collection group
queries, et pour chaque document possédant au moins un des 3 champs à plat :
écrit le champ "dates" imbriqué puis supprime les champs à plat.

Prérequis : service-account.json à côté de ce script (voir
seed_gerance_test_data.py pour la procédure de récupération).

À exécuter seulement après déploiement du code (post.dart,
icon_modify_or_delette.dart, firestore_post_repository.dart,
functions_python/main.py) ET des index Firestore mis à jour
(firestore.indexes.json, "dates.timeStamp") - sinon les posts non encore
migrés disparaissent temporairement des vues triées par date tant que la
reprise n'a pas tourné.

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_post_dates_field.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

LEGACY_DATE_FIELDS = [
    "timeStamp",
    "declaredDate",
    "dateClosed",
]


def migrate_collection_group(name):
    docs = list(db.collection_group(name).stream())
    migrated = 0
    skipped = 0

    batch = db.batch()
    pending = 0

    for doc in docs:
        data = doc.to_dict()

        if not any(field in data for field in LEGACY_DATE_FIELDS):
            skipped += 1
            continue

        dates = {field: data[field] for field in LEGACY_DATE_FIELDS if field in data}
        update = {"dates": dates}
        update.update({field: firestore.DELETE_FIELD for field in LEGACY_DATE_FIELDS if field in data})

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


migrate_collection_group("posts")
migrate_collection_group("signalements")
