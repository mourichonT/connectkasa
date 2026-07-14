"""
Script one-shot : uniformise les Contact existants (residences/*/contacts/*
et emergencyContactsFr, en lecture seule depuis le client - allow write: if
false dans firestore.rules, ne peut être migré que par un script admin) vers
le nouveau format nested address {street, complement, zipCode, city,
codeQualite}, au lieu des champs à plat num/street/zipcode/city.

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_contact_address.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

LEGACY_KEYS = ("num", "street", "zipcode", "city")


def normalize_contact_address(data):
    """Construit le nested address à partir des champs à plat num/street/
    zipcode/city (déjà migré si 'address' est présent - ne touche à rien
    dans ce cas)."""
    street = " ".join(
        p.strip() for p in (data.get("num"), data.get("street"))
        if isinstance(p, str) and p.strip()
    )
    return {
        "street": street,
        "complement": None,
        "zipCode": data.get("zipcode", ""),
        "city": data.get("city", ""),
        "codeQualite": "60",
    }


def migrate_contact_doc(doc_ref, data):
    if isinstance(data.get("address"), dict):
        return False  # déjà migré

    updates = {"address": normalize_contact_address(data)}
    for key in LEGACY_KEYS:
        if key in data:
            updates[key] = firestore.DELETE_FIELD
    doc_ref.update(updates)
    return True


count = 0

for res_doc in db.collection("residences").stream():
    for contact_doc in res_doc.reference.collection("contacts").stream():
        data = contact_doc.to_dict() or {}
        if migrate_contact_doc(contact_doc.reference, data):
            count += 1
            print(f"Migre : residences/{res_doc.id}/contacts/{contact_doc.id}")

for contact_doc in db.collection("emergencyContactsFr").stream():
    data = contact_doc.to_dict() or {}
    if migrate_contact_doc(contact_doc.reference, data):
        count += 1
        print(f"Migre : emergencyContactsFr/{contact_doc.id}")

print(f"\n{count} contact(s) migre(s).")
