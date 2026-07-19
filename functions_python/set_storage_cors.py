"""
Script one-shot : configure le CORS du bucket Storage konodal-dev, absent par
défaut (confirmé : la réponse HTTP de firebasestorage.googleapis.com pour un
objet public ne contient aucun header Access-Control-Allow-Origin, même avec
un Origin envoyé). Sans ça, une balise <img> affiche l'image normalement
(pas besoin de CORS pour ça), mais toute lecture programmatique cross-origin
des pixels (canvas, fetch+blob) échoue silencieusement - cas rencontré avec
html2canvas-pro lors de l'export PDF côté konodal_bo (images vides dans le
PDF généré).

Le CORS ne change PAS qui peut télécharger un objet (déjà accessible à
quiconque possède l'URL avec token, CORS ou pas) - il ne fait qu'autoriser
une page JS d'une origine précise à LIRE les octets. Scope volontairement
restreint aux origines réelles du BO (pas de wildcard "*").

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python set_storage_cors.py
"""
import firebase_admin
from firebase_admin import credentials, storage

STORAGE_BUCKET = "konodal-dev.firebasestorage.app"

# À compléter avec le domaine de prod du BO dès qu'il est déployé quelque
# part (Firebase Hosting ou autre) - pour l'instant seul le dev local a
# besoin d'accéder aux pixels cross-origin (export PDF).
ALLOWED_ORIGINS = [
    "http://localhost:5173",
]

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
bucket = storage.bucket(STORAGE_BUCKET)

print("CORS actuel :", bucket.cors)

bucket.cors = [
    {
        "origin": ALLOWED_ORIGINS,
        "method": ["GET"],
        "maxAgeSeconds": 3600,
        "responseHeader": ["Content-Type", "Content-Length", "Content-Disposition"],
    }
]
bucket.update()

print("CORS mis à jour :", bucket.cors)
