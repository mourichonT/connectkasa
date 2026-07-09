"""
Script one-shot : recrée un jeu de données de test propre pour toute
l'app - 3 résidences, chacune avec 5 lots "Appartement" + 5 lots "Place
de parking".

Supprime d'abord TOUTES les résidences existantes (et leurs
sous-collections : lot, contacts, post, chat, structure, mail) ainsi que
les documents User orphelins (un doc User/{uid} sans compte Firebase
Auth correspondant, et leurs sous-collections lots/private/garants/
demandes_loc) - demandé explicitement par l'utilisateur.

Réutilise 5 comptes réels déjà existants (Auth + doc User valides, hors
compte admin connectkasadev@gmail.com) comme propriétaires/locataires,
comme demandé (2 locataires, 3 propriétaires, pas de compte fictif) :
  - 3 propriétaires : Xlw2lBjwVwQxlQeGuN2N4L1Gkxj2 (Thibault Mourichon),
    TynyVZWwTpXRtu1nWRkVfPpCzD42 (Jules Poitoux / Doe Janette),
    CyslD1TEbQPEhNchXYdgWs5WVA92 (Maëlys-gaëlle Martin)
  - 2 locataires : NTHNsJwR2QVsXYUOq08sK38OqpZ2 (Doe Done),
    ilnPJhdcI1U6aM2ypaZF9RRpJKI3 (Sara Megloud)

Un seul appartement par résidence reçoit un propriétaire (+ locataire
pour 2 des 3 résidences) ; les 27 autres lots restent vides faute de
compte supplémentaire disponible, conformément à la demande explicite
de ne pas fabriquer d'utilisateurs fictifs.

Écrit aussi la dénormalisation User/{uid}/lots/{lotId} nécessaire pour
que ces comptes voient effectivement le lot dans le sélecteur de l'app
(cf. addLotToUser dans firestore_user_repository.dart), en plus de
Residence/{id}/lot/{id}.idProprietaire/idLocataire.

Hors périmètre (non inclus) : contacts de résidence, gérance/syndic,
structures (bâtiments) en sous-collection dédiée, posts/événements/
commentaires/chat. Uniquement résidences + lots, comme demandé.

Exécution : depuis functions_python/, avec le venv activé :
    python seed_test_residences.py
"""
import firebase_admin
from firebase_admin import credentials, firestore, auth

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()

ADMIN_UID = "0hR1IOPOcuTujkZTOP6Bwuqa3K13"

OWNERS = [
    "Xlw2lBjwVwQxlQeGuN2N4L1Gkxj2",
    "TynyVZWwTpXRtu1nWRkVfPpCzD42",
    "CyslD1TEbQPEhNchXYdgWs5WVA92",
]
TENANTS = [
    "NTHNsJwR2QVsXYUOq08sK38OqpZ2",
    "ilnPJhdcI1U6aM2ypaZF9RRpJKI3",
]

RESIDENCES = [
    {
        "id": "lesJardinsFleuris",
        "name": "Les Jardins Fleuris",
        "numero": "12",
        "voie": "rue",
        "street": "des Lilas",
        "zipCode": "75011",
        "city": "Paris",
    },
    {
        "id": "residenceDuParc",
        "name": "Résidence du Parc",
        "numero": "45",
        "voie": "avenue",
        "street": "Victor Hugo",
        "zipCode": "69003",
        "city": "Lyon",
    },
    {
        "id": "villaSoleil",
        "name": "Villa Soleil",
        "numero": "8",
        "voie": "boulevard",
        "street": "Gambetta",
        "zipCode": "33000",
        "city": "Bordeaux",
    },
]

# uid admin exclu explicitement de tout traitement (jamais touché).
assert ADMIN_UID not in OWNERS and ADMIN_UID not in TENANTS

# --- Étape 1 : suppression de l'existant ---

print("=" * 70)
print("SUPPRESSION DES RÉSIDENCES EXISTANTES")
print("=" * 70)
for res_doc in db.collection("Residence").stream():
    print(f"  Suppression Residence/{res_doc.id}...")
    db.recursive_delete(res_doc.reference)
print("Terminé.")

print()
print("=" * 70)
print("SUPPRESSION DES DOCUMENTS User ORPHELINS (pas de compte Auth)")
print("=" * 70)
auth_uids = {u.uid for u in auth.list_users().iterate_all()}
orphan_count = 0
for user_doc in db.collection("User").stream():
    if user_doc.id != ADMIN_UID and user_doc.id not in auth_uids:
        print(f"  Suppression User/{user_doc.id} (orphelin)...")
        db.recursive_delete(user_doc.reference)
        orphan_count += 1
print(f"Terminé ({orphan_count} orphelin(s) supprimé(s)).")

print()
print("=" * 70)
print("NETTOYAGE DES ANCIENNES RÉFÉRENCES DE LOTS (comptes réutilisés)")
print("=" * 70)
for uid in OWNERS + TENANTS:
    old_lots = list(
        db.collection("User").document(uid).collection("lots").stream()
    )
    for lot_doc in old_lots:
        print(f"  Suppression User/{uid}/lots/{lot_doc.id} (résidence supprimée)...")
        lot_doc.reference.delete()

# --- Étape 2 : création des résidences + lots ---

# index résidence (0/1/2) -> (idProprietaire, idLocataire) pour le seul
# appartement assigné de cette résidence.
APARTMENT_ASSIGNMENTS = {
    0: (["Xlw2lBjwVwQxlQeGuN2N4L1Gkxj2"], ["NTHNsJwR2QVsXYUOq08sK38OqpZ2"]),
    1: (["TynyVZWwTpXRtu1nWRkVfPpCzD42"], []),
    2: (["CyslD1TEbQPEhNchXYdgWs5WVA92"], ["ilnPJhdcI1U6aM2ypaZF9RRpJKI3"]),
}

print()
print("=" * 70)
print("CRÉATION DES RÉSIDENCES + LOTS")
print("=" * 70)
for i, res in enumerate(RESIDENCES):
    res_id = res["id"]
    res_ref = db.collection("Residence").document(res_id)
    res_ref.set({
        "name": res["name"],
        "numero": res["numero"],
        "voie": res["voie"],
        "street": res["street"],
        "zipCode": res["zipCode"],
        "city": res["city"],
        "mail_contact": "",
        "id": res_id,
        "csmembers": [],
        "nombreLot": 10,
    })
    print(f"Créé Residence/{res_id} ({res['name']})")

    owner_ids, tenant_ids = APARTMENT_ASSIGNMENTS[i]
    created = 0

    for lot_type, count, prefix in [
        ("Appartement", 5, "A"),
        ("Place de parking", 5, "P"),
    ]:
        for n in range(1, count + 1):
            lot_ref = res_ref.collection("lot").document()
            lot_id = lot_ref.id
            ref_lot = f"{prefix}{n}"
            # Seul le premier appartement de la résidence reçoit les
            # comptes réels assignés ; tout le reste (y compris tous les
            # parkings) reste vide, faute de comptes supplémentaires
            # disponibles (demande explicite : pas d'utilisateur fictif).
            is_assigned_slot = lot_type == "Appartement" and n == 1
            id_proprietaire = list(owner_ids) if is_assigned_slot else []
            id_locataire = list(tenant_ids) if is_assigned_slot else []

            lot_ref.set({
                "id": lot_id,
                "refLot": ref_lot,
                "batiment": "Bâtiment A",
                "lot": ref_lot,
                # typeLot = nature physique du lot ("Appartement", "Place de
                # parking"...), affichée partout dans l'app. type = statut
                # d'occupation ("Location longue durée", "Propriétaire
                # occupant"...), rempli plus tard via l'écran dédié "Ma
                # gestion locative" - jamais dupliqué avec typeLot, vide à
                # la création comme un vrai nouveau lot dans l'app.
                "typeLot": lot_type,
                "type": "",
                "idProprietaire": id_proprietaire,
                "idLocataire": id_locataire,
            })
            created += 1

            # Dénormalisation nécessaire pour que ces comptes voient le
            # lot dans le sélecteur de l'app, ET pour que
            # firestore.rules -> isResidenceMember() les autorise à lire
            # les posts/docs/mail de cette résidence (sans ce champ sur
            # le doc User lui-même, tout accès résidence-scopé échoue en
            # PERMISSION_DENIED - bug vécu en oubliant cette ligne au
            # premier passage de ce script).
            for uid in id_proprietaire:
                db.collection("User").document(uid).set(
                    {"residencesIds": firestore.ArrayUnion([res_id])},
                    merge=True,
                )
                db.collection("User").document(uid).collection(
                    "lots"
                ).document(lot_id).set({
                    "colorSelected": "ff48775b",
                    "nameLot": ref_lot,
                    "residenceId": res_id,
                    "StatutResident": "Propriétaire",
                })
            for uid in id_locataire:
                db.collection("User").document(uid).set(
                    {"residencesIds": firestore.ArrayUnion([res_id])},
                    merge=True,
                )
                db.collection("User").document(uid).collection(
                    "lots"
                ).document(lot_id).set({
                    "colorSelected": "ff48775b",
                    "nameLot": ref_lot,
                    "residenceId": res_id,
                    "StatutResident": "Locataire",
                })

    print(f"  {created} lots créés (5 Appartement + 5 Place de parking) - "
          f"propriétaire(s) {owner_ids or '(aucun)'}, "
          f"locataire(s) {tenant_ids or '(aucun)'} sur A1")

print()
print("Terminé.")
