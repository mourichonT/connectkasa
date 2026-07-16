"""
Script one-shot : renomme les valeurs du champ `statut` des posts
sinistres/incivilités existants pour passer du workflow à 3 étapes
("En attente" / "Prise en compte" / "Terminé") au nouveau workflow à 4
étapes ("Non envoyé" / "Transmis" / "En cours" / "Terminé"), suite au
renommage de StatutPostList (statut_post_list.dart).

Mapping appliqué :
    "En attente"      -> "Non envoyé"
    "Prise en compte" -> "Transmis"
    "Terminé"         -> inchangé
    (tout autre "En cours" éventuel déjà présent : inchangé)

Portée : residences/{id}/posts/{id} ET residences/{id}/posts/{id}/signalements/{id}
(les signalements portent aussi un champ `statut` initialisé à la création,
cf. submit_post_controller.dart _buildPost), filtrés sur type in
["sinistres", "incivilites"] (seuls types pilotés par ce Stepper, cf.
icon_modify_or_delette.dart).

Prérequis : télécharger une clé de service account depuis la console
Firebase (Paramètres du projet > Comptes de service > Générer une nouvelle
clé privée), l'enregistrer à côté de ce script sous le nom
"service-account.json" (jamais commité).

Exécution : depuis functions_python/, avec le venv activé :
    python migrate_sinistre_status_v2.py           # dry-run (aucune écriture)
    python migrate_sinistre_status_v2.py --apply    # applique les renommages
"""
import sys

import firebase_admin
from firebase_admin import credentials, firestore

STATUS_RENAME = {
    "En attente": "Non envoyé",
    "Prise en compte": "Transmis",
}
TARGET_TYPES = ("sinistres", "incivilites")

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

apply_changes = "--apply" in sys.argv


def migrate_doc(ref, data, label):
    old_statut = data.get("statut")
    new_statut = STATUS_RENAME.get(old_statut)
    if new_statut is None:
        return 0
    print(f"{'[APPLY]' if apply_changes else '[DRY-RUN]'} {label} : "
          f"\"{old_statut}\" -> \"{new_statut}\"")
    if apply_changes:
        ref.update({"statut": new_statut})
    return 1


count = 0
for residence in db.collection("residences").stream():
    posts_ref = residence.reference.collection("posts")
    for post in posts_ref.where("type", "in", list(TARGET_TYPES)).stream():
        post_data = post.to_dict() or {}
        count += migrate_doc(
            post.reference, post_data, f"residences/{residence.id}/posts/{post.id}"
        )

        for signalement in post.reference.collection("signalements").stream():
            sig_data = signalement.to_dict() or {}
            count += migrate_doc(
                signalement.reference,
                sig_data,
                f"residences/{residence.id}/posts/{post.id}/signalements/{signalement.id}",
            )

print(f"\n{count} document(s) {'migré(s)' if apply_changes else 'à migrer'}.")
if not apply_changes:
    print("Aucune écriture effectuée (dry-run). Relancer avec --apply pour appliquer.")
