"""
Script one-shot : supprime les lots dupliqués (même bâtiment + numéro) au
sein d'une résidence. Constaté sur residences/2Jkfw0yCIxlBAzI9vPB0 : 162
documents pour seulement 27 combos (bâtiment, lot) uniques, certains
dupliqués jusqu'à 12 fois - vraisemblablement dû à un ancien bug de
createOrUpdateLot (déjà corrigé depuis, cf. commentaires dans
firestore_lot_repository.dart) créant un nouveau document au lieu de
mettre à jour l'existant.

Pour chaque groupe (bâtiment, lot) en double, garde UN SEUL document :
priorité à celui qui a idProprietaire/idLocataire renseigné (données
réelles), sinon le plus ancien (createTime). Supprime tous les autres.

Vérifié au préalable (--dry-run de ce script + requête manuelle) : aucun
groupe dupliqué n'a plus d'un document avec des données résident - pas de
risque de perte de rattachement propriétaire/locataire.

Exécution : depuis functions_python/, avec le venv activé :
    python purge_duplicate_lots.py --residence <residenceId> [--dry-run]
"""
import sys

import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()
DRY_RUN = "--dry-run" in sys.argv

if "--residence" not in sys.argv:
    print("Usage: python purge_duplicate_lots.py --residence <residenceId> [--dry-run]")
    sys.exit(1)
residence_id = sys.argv[sys.argv.index("--residence") + 1]


def has_resident_data(data):
    return bool(data.get("idProprietaire")) or bool(data.get("idLocataire"))


def purge():
    lots_ref = db.collection("residences").document(residence_id).collection("lots")
    lots = list(lots_ref.stream())
    print(f"{len(lots)} lot(s) trouvé(s) pour la résidence {residence_id}.")

    by_combo = {}
    for doc in lots:
        data = doc.to_dict() or {}
        combo = (data.get("batiment") or "", data.get("lot") or "")
        by_combo.setdefault(combo, []).append(doc)

    duplicates_deleted = 0
    for combo, docs in by_combo.items():
        if len(docs) <= 1:
            continue

        with_data = [d for d in docs if has_resident_data(d.to_dict() or {})]
        if len(with_data) > 1:
            print(f"ATTENTION - combo {combo} : {len(with_data)} documents ont "
                  f"des données résident, ignoré (résolution manuelle requise) : "
                  f"{[d.id for d in with_data]}")
            continue

        if with_data:
            keep = with_data[0]
        else:
            # Le plus ancien (create_time) parmi les identiques.
            keep = min(docs, key=lambda d: d.create_time)

        to_delete = [d for d in docs if d.id != keep.id]
        print(f"Combo {combo} : garde {keep.id}, supprime {len(to_delete)} "
              f"doublon(s) : {[d.id for d in to_delete]}")
        for d in to_delete:
            duplicates_deleted += 1
            if not DRY_RUN:
                d.reference.delete()

    print(f"\n{duplicates_deleted} document(s) de lot dupliqué(s) "
          f"{'à supprimer' if DRY_RUN else 'supprimé(s)'}.")
    if DRY_RUN:
        print("(dry-run : aucune écriture effectuée)")


purge()
