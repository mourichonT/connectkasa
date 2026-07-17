"""
Script one-shot (lecture seule par défaut) : détecte les posts
sinistres/incivilités dont le champ `isVideo` ne correspond pas au vrai
type du fichier Storage (`contentType`), suite au bug de détection
d'extension sur Windows (camera_files_choices.dart, corrigé) qui faisait
passer des vidéos pour des images côté `isVideo`.

Le nom du fichier Storage est un UUID sans extension (cf. commentaire sur
Post._pathImage) : on ne peut pas déduire le type depuis l'URL, seul le
`contentType` réel de l'objet Storage fait foi.

Usage : depuis functions_python/, avec le venv activé :
    python scan_isvideo_mismatch.py            # dry-run (aucune écriture)
    python scan_isvideo_mismatch.py --apply    # corrige isVideo en base
"""
import sys
from urllib.parse import unquote, urlparse

import firebase_admin
from firebase_admin import credentials, firestore, storage

apply_changes = "--apply" in sys.argv

firebase_admin.initialize_app(
    credentials.Certificate("service-account.json"),
    {"storageBucket": "konodal-dev.firebasestorage.app"},
)
db = firestore.client()
bucket = storage.bucket()


def storage_path_from_url(url):
    """Extrait le chemin d'objet Storage (ex: residences/x/sinistres/y) d'une
    URL de download Firebase Storage (.../o/<path url-encodé>?alt=media...)."""
    if not url:
        return None
    parsed = urlparse(url)
    if "/o/" not in parsed.path:
        return None
    encoded_path = parsed.path.split("/o/", 1)[1]
    return unquote(encoded_path)


checked = 0
mismatches = []

for residence in db.collection("residences").stream():
    posts_ref = residence.reference.collection("posts")
    for post in posts_ref.where("type", "in", ["sinistres", "incivilites"]).stream():
        data = post.to_dict() or {}
        path_image = data.get("pathImage")
        if not path_image:
            continue

        storage_path = storage_path_from_url(path_image)
        if not storage_path:
            continue

        blob = bucket.blob(storage_path)
        blob.reload() if blob.exists() else None
        if not blob.exists():
            print(f"SKIP residences/{residence.id}/posts/{post.id} : "
                  f"fichier Storage introuvable ({storage_path})")
            continue

        checked += 1
        content_type = blob.content_type or ""
        is_video_actual = content_type.startswith("video/")
        is_video_flag = bool(data.get("isVideo"))

        if is_video_actual != is_video_flag:
            mismatches.append((post.reference, residence.id, post.id, is_video_actual, content_type))
            print(f"{'[APPLY]' if apply_changes else '[DRY-RUN]'} "
                  f"residences/{residence.id}/posts/{post.id} : "
                  f"isVideo={is_video_flag} mais contentType={content_type} "
                  f"-> devrait être isVideo={is_video_actual}")
            if apply_changes:
                post.reference.update({"isVideo": is_video_actual})

print(f"\n{checked} post(s) vérifié(s), {len(mismatches)} incohérence(s) trouvée(s).")
if mismatches and not apply_changes:
    print("Aucune écriture effectuée (dry-run). Relancer avec --apply pour corriger.")
