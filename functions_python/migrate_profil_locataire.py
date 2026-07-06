"""
Script one-shot : migre les données existantes vers la nouvelle structure
CRIT 2 (aplatissement de la sous-collection "profil_locataire").

Ancien format : User/{uid}/profil_locataire/{uid} (document unique, ID
toujours = uid) avec sa propre sous-collection garants/{garantId} (+ leurs
documents).

Nouveau format :
  - User/{uid}/private/profilLocataire (revenus, activities, dependent,
    familySituation, phone) - même niveau de confidentialité qu'avant
    (owner + bailleur partagé), voir firestore.rules. Les champs vivent à
    part de User/{uid} lui-même car ce dernier est lisible par tout
    utilisateur connecté (affichage du profil ailleurs dans l'app).
  - User/{uid}/garants/{garantId} (+ leurs documents) directement, un
    niveau de nesting en moins.

Prérequis : service-account.json à côté de ce script (voir
seed_gerance_test_data.py pour la procédure de récupération).

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_profil_locataire.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()


def migrate_user(user_doc):
    uid = user_doc.id
    profil_ref = user_doc.reference.collection("profil_locataire").document(uid)
    profil_snap = profil_ref.get()

    if not profil_snap.exists:
        return False

    # 1. Champs du profil locataire -> private/profilLocataire.
    private_ref = user_doc.reference.collection("private").document(
        "profilLocataire"
    )
    private_ref.set(profil_snap.to_dict() or {}, merge=True)

    # 2. Garants (+ leurs documents) -> User/{uid}/garants directement.
    for garant_doc in profil_ref.collection("garants").stream():
        new_garant_ref = user_doc.reference.collection("garants").document(
            garant_doc.id
        )
        new_garant_ref.set(garant_doc.to_dict() or {})

        for doc in garant_doc.reference.collection("documents").stream():
            new_garant_ref.collection("documents").document(doc.id).set(
                doc.to_dict() or {}
            )

    # 3. Supprime l'ancienne sous-collection profil_locataire (doc + garants
    # + leurs documents), maintenant dupliquée dans le nouveau format.
    db.recursive_delete(profil_ref)

    return True


migrated = 0
skipped = 0

for user_doc in db.collection("User").stream():
    if migrate_user(user_doc):
        migrated += 1
    else:
        skipped += 1

print(f"{migrated} utilisateur(s) migré(s), {skipped} sans profil_locataire.")
