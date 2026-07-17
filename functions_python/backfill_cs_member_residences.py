"""
Backfill one-shot : initialise users/{uid}.csMemberResidencesIds pour tous
les CS members déjà existants (residences/{id}.csmembers), AVANT le
déploiement de la Cloud Function sync_cs_member_residences (qui ne maintient
ce champ qu'à partir des écritures FUTURES sur csmembers, pas de l'état déjà
en base) et des nouvelles règles Firestore qui en dépendent
(isCsMemberOfAnyResidence, collection racine contacts/{id}).

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python backfill_cs_member_residences.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

all_uids = set()
for res_doc in db.collection("residences").stream():
    all_uids.update((res_doc.to_dict() or {}).get("csmembers", []))

for uid in all_uids:
    residence_ids = sorted(
        doc.id for doc in db.collection("residences")
        .where("csmembers", "array_contains", uid).stream()
    )
    db.collection("users").document(uid).set(
        {"csMemberResidencesIds": residence_ids}, merge=True)
    print(f"users/{uid}.csMemberResidencesIds = {residence_ids}")

print(f"\n{len(all_uids)} CS member(s) backfille(s).")
