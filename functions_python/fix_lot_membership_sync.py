"""
Script one-shot : corrige les lots où idLocataire/idProprietaire manque
côté Residence/{id}/lot/{lotId} alors qu'un User/{uid}/lots/{lotId}
correspondant existe (bug du flux "Rattacher un lot" - AttachExistingLotPage
- qui n'écrivait que côté User, jamais côté Residence, cf. commit sur
attach_existing_lot_page.dart).

Pour chaque document User/{uid}/lots/{lotId} :
  - lit residenceId + statutResident
  - si statutResident vaut exactement "Propriétaire" ou "Locataire" et que
    uid n'est déjà dans NI idProprietaire NI idLocataire côté
    Residence/{residenceId}/lot/{lotId}, l'ajoute au bon tableau via
    arrayUnion
  - si statutResident est vide/absent/autre, ignore ce document (champ
    ambigu - ex. propriétaire d'origine à la création du lot, déjà
    présent normalement dans idProprietaire - deviner aurait pu créer un
    doublon incorrect, comme observé une fois en exécutant ce script)

Exécution : depuis functions_python/, avec le venv activé :
    python fix_lot_membership_sync.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

fixed = 0
already_ok = 0
skipped_no_lot = 0
skipped_ambiguous = 0

for user_doc in db.collection("User").stream():
    uid = user_doc.id
    for user_lot in user_doc.reference.collection("lots").stream():
        data = user_lot.to_dict() or {}
        residence_id = data.get("residenceId")
        lot_id = user_lot.id
        statut = data.get("statutResident")

        if not residence_id:
            continue

        if statut not in ("Propriétaire", "Locataire"):
            skipped_ambiguous += 1
            continue

        lot_ref = (
            db.collection("Residence")
            .document(residence_id)
            .collection("lot")
            .document(lot_id)
        )
        lot_snap = lot_ref.get()
        if not lot_snap.exists:
            skipped_no_lot += 1
            print(f"SKIP User {uid}: Residence/{residence_id}/lot/{lot_id} introuvable")
            continue

        lot_data = lot_snap.to_dict() or {}
        already_proprietaire = uid in (lot_data.get("idProprietaire") or [])
        already_locataire = uid in (lot_data.get("idLocataire") or [])

        if already_proprietaire or already_locataire:
            already_ok += 1
            continue

        field = "idProprietaire" if statut == "Propriétaire" else "idLocataire"
        lot_ref.update({field: firestore.ArrayUnion([uid])})
        fixed += 1
        print(f"FIXED User {uid} -> Residence/{residence_id}/lot/{lot_id}.{field}")

print(
    f"\n{fixed} lot(s) corrigé(s), {already_ok} déjà à jour, "
    f"{skipped_no_lot} lot introuvable côté résidence, "
    f"{skipped_ambiguous} statutResident ambigu ignoré."
)
