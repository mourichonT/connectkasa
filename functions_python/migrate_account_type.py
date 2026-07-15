"""
Script one-shot : ajoute accountType="utilisateur" à tous les comptes
users/{uid} existants qui n'ont pas encore ce champ (ajouté après coup au
modèle User, cf. lib/models/pages_models/user.dart). Cette app ne crée que
des comptes 'utilisateur' - tous les comptes déjà en base à ce jour le sont
donc forcément, aucun compte 'professionnel'/'superAdmin' n'a encore été
créé (ce sera fait plus tard par le futur backoffice web).

Ne touche jamais un document qui a déjà un champ accountType (défensif, au
cas où un tel compte aurait été créé entre-temps hors-app).

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_account_type.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

migrated = 0
skipped = 0

for user_doc in db.collection("users").stream():
    data = user_doc.to_dict() or {}
    if "accountType" in data:
        skipped += 1
        continue
    user_doc.reference.update({"accountType": "utilisateur"})
    migrated += 1

print(f"{migrated} compte(s) migré(s) vers accountType='utilisateur', "
      f"{skipped} déjà à jour.")
