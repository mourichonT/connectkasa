"""
Script one-shot : consolidation du modèle "agent" de gérance.

Avant ce chantier, un agent (nom/mail/téléphone) était dupliqué à 3 endroits :
gerances/{id}.services.<type>.agents[] (maintenu à la main via konodal_bo),
gerances/{id}.<type>AgentUids (tableau d'uids, déjà correct), et
gerances/{id}/contacts/{id} (index dérivé, régénéré par la Cloud Function
sync_gerance_contacts pour la recherche par email). users/{uid} devient la
seule source de vérité ; la recherche par email itère maintenant sur `users`
filtré par accountType (cf. FirestoreAgencyRepository).

Ce script :
1. Parcourt residences/{id}.geranceRef, residences/{id}/lots/{lotId}.geranceRef
   et residences/{id}/structures/{structureId}.geranceRef : partout où
   geranceRef.agentMail est défini, retrouve l'uid correspondant dans
   gerances/{geranceId}.services.<serviceType>.agents[] (par mail), écrit
   geranceRef.agentUid, supprime geranceRef.agentMail.
2. Supprime toute la sous-collection gerances/*/contacts/* (dérivée, plus lue
   par personne après ce chantier).
3. Supprime le champ services.<type>.agents sur chaque gerances/{id} (konodal_bo
   ne doit plus en dépendre - migration côté BO faite en parallèle) ; garde
   services.<type>.mail/phone (contact générique du service, inchangé).

Prérequis : service-account.json à côté de ce script.

Exécution : depuis functions_python/, avec le venv activé, APRÈS déploiement
du code applicatif (firestore.rules + FirestoreAgencyRepository) :
    python migrate_gerance_ref_agent_uid.py [--dry-run]
"""
import sys

import firebase_admin
from firebase_admin import credentials, firestore

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
db = firestore.client()
DRY_RUN = "--dry-run" in sys.argv

SERVICE_TYPES = ("serviceSyndic", "geranceLocative")


def _build_agent_uid_by_mail():
    """gerances/{id} -> {serviceType: {mail: uid}}, depuis services.<type>.agents[]."""
    lookup = {}
    for gerance_doc in db.collection("gerances").stream():
        data = gerance_doc.to_dict() or {}
        services = data.get("services") or {}
        by_service = {}
        for service_type, service in services.items():
            service = service or {}
            by_mail = {}
            for agent in service.get("agents", []):
                mail = agent.get("mail")
                uid = agent.get("uid")
                if mail and uid:
                    by_mail[mail] = uid
            by_service[service_type] = by_mail
        lookup[gerance_doc.id] = by_service
    return lookup


def _migrate_gerance_ref(doc_ref, data, agent_uid_by_mail, stats):
    gerance_ref = data.get("geranceRef")
    if not gerance_ref or not gerance_ref.get("agentMail"):
        return

    agent_mail = gerance_ref["agentMail"]
    gerance_id = gerance_ref.get("geranceId")
    service_type = gerance_ref.get("serviceType")
    uid = agent_uid_by_mail.get(gerance_id, {}).get(service_type, {}).get(agent_mail)

    print(f"{doc_ref.path} : geranceRef.agentMail={agent_mail!r} -> "
          f"agentUid={uid!r}" + ("" if uid else " (AUCUN MATCH, mail retiré sans uid)"))

    stats["refs_migrated"] += 1
    if not DRY_RUN:
        update = {"geranceRef.agentMail": firestore.DELETE_FIELD}
        if uid:
            update["geranceRef.agentUid"] = uid
        doc_ref.update(update)


def migrate():
    stats = {"refs_migrated": 0, "contacts_deleted": 0, "agents_fields_removed": 0}
    agent_uid_by_mail = _build_agent_uid_by_mail()

    for residence_doc in db.collection("residences").stream():
        residence_data = residence_doc.to_dict() or {}
        _migrate_gerance_ref(residence_doc.reference, residence_data, agent_uid_by_mail, stats)

        for lot_doc in residence_doc.reference.collection("lots").stream():
            _migrate_gerance_ref(lot_doc.reference, lot_doc.to_dict() or {}, agent_uid_by_mail, stats)

        for structure_doc in residence_doc.reference.collection("structures").stream():
            _migrate_gerance_ref(structure_doc.reference, structure_doc.to_dict() or {}, agent_uid_by_mail, stats)

    # collection_group("contacts") matche AUSSI la collection racine
    # /contacts/{id} (annuaire contacts résidence, sans rapport) - même
    # dette technique documentée dans l'ancienne règle firestore.rules
    # ({path=**}/contacts/{contactId}) : on distingue via 'serviceType',
    # présent uniquement sur gerances/{id}/contacts/{id}, jamais sur un
    # contact racine.
    for contact_doc in db.collection_group("contacts").stream():
        if "serviceType" not in (contact_doc.to_dict() or {}):
            continue
        print(f"Suppression : {contact_doc.reference.path}")
        stats["contacts_deleted"] += 1
        if not DRY_RUN:
            contact_doc.reference.delete()

    for gerance_doc in db.collection("gerances").stream():
        data = gerance_doc.to_dict() or {}
        services = data.get("services") or {}
        update = {}
        for service_type in SERVICE_TYPES:
            service = services.get(service_type)
            if service and "agents" in service:
                update[f"services.{service_type}.agents"] = firestore.DELETE_FIELD
        if update:
            print(f"{gerance_doc.reference.path} : retire {list(update.keys())}")
            stats["agents_fields_removed"] += len(update)
            if not DRY_RUN:
                gerance_doc.reference.update(update)

    print(f"\n{stats['refs_migrated']} geranceRef migré(s), "
          f"{stats['contacts_deleted']} contact(s) supprimé(s), "
          f"{stats['agents_fields_removed']} champ(s) services.<type>.agents retiré(s).")
    if DRY_RUN:
        print("(dry-run : aucune écriture effectuée)")


migrate()
