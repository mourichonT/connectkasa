"""
Script one-shot : uniformise tous les objects "address" existants en base au
nouveau format {street, complement, zipCode, city, codeQualite} (cf.
lib/models/pages_models/address.dart). Avant ce script, certains documents
stockaient encore numero/avenue (ou numeros/voie pour gerances) séparément,
sans codeQualite.

Collections concernées :
  - residences/{id}.address
  - residences/{id}.syndicAgency.address
  - residences/{id}/structures/{sid}.syndicAgency.address
  - residences/{id}/lots/{lid}.syndicAgency.address
  - residences/{id}/lots/{lid}.residenceData.address (copie dénormalisée
    affichée directement depuis Lot, cf. Lot.residenceAddress)
  - users/{uid}/private/profilLocataire.address
  - users/{uid}/garants/{gid}.address
  - gerances/{id}.address (anciennement à plat directement sur le document)

codeQualite vaut "60" (validation manuelle) pour toutes les données
préexistantes, aucune n'ayant été saisie via l'autocomplétion API Adresse.

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_address_uniformize.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

LEGACY_ADDRESS_KEYS = (
    "numero", "numeros", "avenue", "voie", "street", "zipCode", "city",
    "complement", "codeQualite",
)


def normalize_address(raw):
    """Convertit un dict address (nouveau ou ancien format) vers la forme
    uniformisée {street, complement, zipCode, city, codeQualite}."""
    raw = raw or {}
    if "codeQualite" in raw:
        return {
            "street": raw.get("street", ""),
            "complement": raw.get("complement"),
            "zipCode": raw.get("zipCode", ""),
            "city": raw.get("city", ""),
            "codeQualite": raw.get("codeQualite") or "60",
        }
    parts = [
        raw.get("numero") or raw.get("numeros"),
        raw.get("avenue") or raw.get("voie"),
        raw.get("street"),
    ]
    street = " ".join(p.strip() for p in parts if isinstance(p, str) and p.strip())
    return {
        "street": street,
        "complement": raw.get("complement"),
        "zipCode": raw.get("zipCode", ""),
        "city": raw.get("city", ""),
        "codeQualite": "60",
    }


def migrate_nested_agency(data, prefix, updates):
    """Normalise data[prefix]['address'] si présent (syndicAgency imbriquée)."""
    agency = data.get(prefix)
    if isinstance(agency, dict) and isinstance(agency.get("address"), dict):
        new_addr = normalize_address(agency["address"])
        if new_addr != agency["address"]:
            updates[f"{prefix}.address"] = new_addr


counts = {
    "residences": 0,
    "residences.syndicAgency": 0,
    "structures.syndicAgency": 0,
    "lots.syndicAgency": 0,
    "lots.residenceData": 0,
    "profilLocataire": 0,
    "garants": 0,
    "gerances": 0,
}

for res_doc in db.collection("residences").stream():
    data = res_doc.to_dict() or {}
    updates = {}

    if isinstance(data.get("address"), dict):
        new_addr = normalize_address(data["address"])
        if new_addr != data["address"]:
            updates["address"] = new_addr
            counts["residences"] += 1

    migrate_nested_agency(data, "syndicAgency", updates)
    if "syndicAgency.address" in updates:
        counts["residences.syndicAgency"] += 1

    if updates:
        res_doc.reference.update(updates)

    for struct_doc in res_doc.reference.collection("structures").stream():
        sdata = struct_doc.to_dict() or {}
        supdates = {}
        migrate_nested_agency(sdata, "syndicAgency", supdates)
        if supdates:
            struct_doc.reference.update(supdates)
            counts["structures.syndicAgency"] += 1

    for lot_doc in res_doc.reference.collection("lots").stream():
        ldata = lot_doc.to_dict() or {}
        lupdates = {}

        migrate_nested_agency(ldata, "syndicAgency", lupdates)
        if "syndicAgency.address" in lupdates:
            counts["lots.syndicAgency"] += 1

        residence_data = ldata.get("residenceData")
        if isinstance(residence_data, dict):
            if isinstance(residence_data.get("address"), dict):
                new_addr = normalize_address(residence_data["address"])
                if new_addr != residence_data["address"]:
                    lupdates["residenceData.address"] = new_addr
                    counts["lots.residenceData"] += 1
            elif "street" in residence_data:
                # Ancienne copie dénormalisée à plat, sans sous-clé 'address'.
                new_addr = normalize_address(residence_data)
                lupdates["residenceData.address"] = new_addr
                for key in LEGACY_ADDRESS_KEYS:
                    if key in residence_data:
                        lupdates[f"residenceData.{key}"] = firestore.DELETE_FIELD
                counts["lots.residenceData"] += 1

        if lupdates:
            lot_doc.reference.update(lupdates)

for user_doc in db.collection("users").stream():
    profil_ref = user_doc.reference.collection("private").document("profilLocataire")
    profil_snap = profil_ref.get()
    if profil_snap.exists:
        pdata = profil_snap.to_dict() or {}
        if isinstance(pdata.get("address"), dict):
            new_addr = normalize_address(pdata["address"])
            if new_addr != pdata["address"]:
                profil_ref.update({"address": new_addr})
                counts["profilLocataire"] += 1

    for garant_doc in user_doc.reference.collection("garants").stream():
        gdata = garant_doc.to_dict() or {}
        if isinstance(gdata.get("address"), dict):
            new_addr = normalize_address(gdata["address"])
            if new_addr != gdata["address"]:
                garant_doc.reference.update({"address": new_addr})
                counts["garants"] += 1

for gerance_doc in db.collection("gerances").stream():
    data = gerance_doc.to_dict() or {}
    updates = {}

    if isinstance(data.get("address"), dict):
        new_addr = normalize_address(data["address"])
        if new_addr != data["address"]:
            updates["address"] = new_addr
    elif any(k in data for k in ("street", "numeros", "numero", "avenue", "voie")):
        # Ancien format seed_gerance_test_data.py : champs à plat sur le
        # document lui-même (pas de sous-clé 'address').
        new_addr = normalize_address(data)
        updates["address"] = new_addr
        for key in LEGACY_ADDRESS_KEYS:
            if key in data:
                updates[key] = firestore.DELETE_FIELD

    if updates:
        gerance_doc.reference.update(updates)
        counts["gerances"] += 1

print("Migration terminée. Documents modifiés :")
for label, n in counts.items():
    print(f"  - {label}: {n}")
