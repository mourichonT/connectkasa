"""
Script one-shot : déplace compagnyBuy depuis users/{uid} (top-level) vers
users/{uid}/lots/{lotId} (cf. lib/models/pages_models/user_temp.dart,
lib/core/repositories/firestore_user_repository.dart - setUser/addLotToUser
écrivent désormais ce champ sur le sous-document du lot concerné, jamais
sur le compte lui-même : un même utilisateur peut posséder plusieurs lots,
achetés ou non via une société, ce n'est pas une propriété du compte).

Pour chaque users/{uid} ayant un champ compagnyBuy à plat :
  - s'il a exactement UN lot dans users/{uid}/lots, la valeur y est copiée
    (merge, ne supprime rien d'autre) ;
  - s'il a zéro ou plusieurs lots, impossible de savoir sans ambiguïté à
    quel lot la valeur s'appliquait à l'origine - le compte est signalé et
    laissé tel quel (compagnyBuy pas supprimé de users/{uid}, à traiter à la
    main).
  - Dans le cas à un seul lot, le champ compagnyBuy est ensuite supprimé de
    users/{uid} (DELETE_FIELD), il ne doit plus y vivre.

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_compagny_buy_to_lot.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

migrated = 0
ambiguous = 0
skipped = 0

for user_doc in db.collection("users").stream():
    data = user_doc.to_dict() or {}
    if "compagnyBuy" not in data:
        skipped += 1
        continue

    lots = list(user_doc.reference.collection("lots").stream())

    if len(lots) != 1:
        ambiguous += 1
        print(f"  ! users/{user_doc.id} : {len(lots)} lot(s), compagnyBuy "
              f"laissé tel quel (à traiter manuellement).")
        continue

    lot_ref = lots[0].reference
    lot_ref.set({"compagnyBuy": data["compagnyBuy"]}, merge=True)
    user_doc.reference.update({"compagnyBuy": firestore.DELETE_FIELD})
    migrated += 1

print(f"{migrated} compte(s) migré(s), {ambiguous} ambigu(s) (plusieurs/aucun "
      f"lot), {skipped} sans compagnyBuy sur users/{{uid}}.")
