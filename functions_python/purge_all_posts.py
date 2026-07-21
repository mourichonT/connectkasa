"""
Script one-shot : supprime TOUS les posts de TOUTES les résidences
(residences/{id}/posts, avec leurs sous-collections signalements/comments/
replies), l'archive deletedPosts, ET les fichiers Storage associés
(pathImage de chaque post/signalement/deletedPost), en repartant du même
parsing d'URL que FirestoreStorageRepository.removeFileFromUrl (Dart) :
tout ce qui suit "/o/" jusqu'au "?" dans l'URL, décodé.

Ne touche pas : adCampaigns, config/adCampaigns, users, lots, contacts,
gerances - uniquement posts/deletedPosts et leurs sous-collections.

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé :
    python purge_all_posts.py --dry-run   # compte seulement, ne supprime rien
    python purge_all_posts.py             # suppression réelle
"""
import sys
from urllib.parse import unquote, urlparse

import firebase_admin
from firebase_admin import credentials, firestore, storage

firebase_admin.initialize_app(
    credentials.Certificate("service-account.json"),
    {"storageBucket": "konodal-dev.firebasestorage.app"},
)
db = firestore.client()
bucket = storage.bucket()
DRY_RUN = "--dry-run" in sys.argv

stats = {
    "posts": 0,
    "signalements": 0,
    "comments": 0,
    "replies": 0,
    "deletedPosts": 0,
    "files_deleted": 0,
    "files_missing_or_failed": 0,
}


def storage_path_from_url(url):
    if not url:
        return None
    try:
        decoded = unquote(url)
        if "/o/" not in decoded:
            return None
        return decoded.split("/o/", 1)[1].split("?", 1)[0]
    except Exception:
        return None


def delete_storage_file(url):
    path = storage_path_from_url(url)
    if not path:
        return
    stats["files_deleted"] += 1
    if DRY_RUN:
        return
    try:
        bucket.blob(path).delete()
    except Exception as e:
        stats["files_deleted"] -= 1
        stats["files_missing_or_failed"] += 1
        print(f"    (storage) échec suppression {path}: {e}")


def delete_comments(post_ref):
    for comment_doc in post_ref.collection("comments").stream():
        for reply_doc in comment_doc.reference.collection("replies").stream():
            stats["replies"] += 1
            if not DRY_RUN:
                reply_doc.reference.delete()
        stats["comments"] += 1
        if not DRY_RUN:
            comment_doc.reference.delete()


def delete_post_tree(post_ref, post_data):
    delete_storage_file(post_data.get("pathImage"))
    for sig_doc in post_ref.collection("signalements").stream():
        sig_data = sig_doc.to_dict() or {}
        delete_storage_file(sig_data.get("pathImage"))
        stats["signalements"] += 1
        if not DRY_RUN:
            sig_doc.reference.delete()
    delete_comments(post_ref)
    if not DRY_RUN:
        post_ref.delete()


def purge():
    for residence_doc in db.collection("residences").stream():
        residence_id = residence_doc.id
        posts_ref = db.collection("residences").document(residence_id).collection("posts")
        residence_post_count = 0
        for post_doc in posts_ref.stream():
            data = post_doc.to_dict() or {}
            delete_post_tree(post_doc.reference, data)
            stats["posts"] += 1
            residence_post_count += 1

        deleted_ref = db.collection("residences").document(residence_id).collection("deletedPosts")
        residence_deleted_count = 0
        for dp_doc in deleted_ref.stream():
            dp_data = dp_doc.to_dict() or {}
            delete_storage_file(dp_data.get("pathImage"))
            stats["deletedPosts"] += 1
            residence_deleted_count += 1
            if not DRY_RUN:
                dp_doc.reference.delete()

        if residence_post_count or residence_deleted_count:
            print(
                f"Résidence {residence_id}: {residence_post_count} post(s), "
                f"{residence_deleted_count} deletedPost(s)"
            )

    print(f"\n{'[DRY RUN] ' if DRY_RUN else ''}Résumé :")
    print(f"  posts               : {stats['posts']}")
    print(f"  signalements        : {stats['signalements']}")
    print(f"  comments            : {stats['comments']}")
    print(f"  replies             : {stats['replies']}")
    print(f"  deletedPosts        : {stats['deletedPosts']}")
    print(f"  fichiers Storage    : {stats['files_deleted']} supprimés, "
          f"{stats['files_missing_or_failed']} introuvables/échecs")
    if DRY_RUN:
        print("\n(dry-run : aucune écriture/suppression effectuée)")


purge()
