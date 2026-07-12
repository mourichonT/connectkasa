# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import scheduler_fn, https_fn, firestore_fn, options, params

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore
import imaplib
import smtplib
import email
import re
import json
from email.header import decode_header
from email.utils import parsedate_to_datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import requests
import os
import tempfile
from datetime import datetime, timedelta, timezone
from io import BytesIO
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

app = initialize_app()


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# IMAP (réception)
IMAP_HOST = 'imap.gmail.com'
IMAP_PORT = 993

# SMTP (envoi) - même boîte Gmail, port SSL classique
SMTP_HOST = 'smtp.gmail.com'
SMTP_PORT = 465

EMAIL_ADDRESS = 'connectkasadev@gmail.com'
# Secret Firebase (jamais en clair dans le code / git) : à définir avec
# `firebase functions:secrets:set EMAIL_PASSWORD`. Déclaré individuellement
# sur chaque décorateur plutôt que via set_global_options(secrets=...) : le
# SDK ne résout pas correctement un SecretParam passé en option globale
# (le nom du secret reste un template CEL non substitué au déploiement).
EMAIL_PASSWORD = params.SecretParam('EMAIL_PASSWORD')

# Extraction de données de carte d'identité (photo_for_id.dart) : à définir
# avec `firebase functions:secrets:set OPENAI_API_KEY`. Ne jamais exposer
# cette clé côté client (Flutter) : l'appel à OpenAI doit toujours transiter
# par ici.
OPENAI_API_KEY = params.SecretParam('OPENAI_API_KEY')
OPENAI_CHAT_COMPLETIONS_URL = 'https://api.openai.com/v1/chat/completions'

# Format exact utilisé côté app (databases_mail_services.dart / mail.dart) :
# "Vous avez un message pour la residence {name} - lot {batiment} {lot}"
SUBJECT_RE = re.compile(
    r"^Vous avez un message pour la residence (.+) - lot (\S+) (\S+)$"
)


# ---------------------------------------------------------------------------
# Helpers - réception (IMAP)
# ---------------------------------------------------------------------------

def resolve_residence_id(db, subject):
    """Retrouve le residenceId Firestore à partir du sujet de l'email."""
    match = SUBJECT_RE.match(subject)
    if not match:
        return None

    residence_name = match.group(1).strip()
    docs = list(
        db.collection('residences')
          .where('name', '==', residence_name)
          .limit(1)
          .stream()
    )
    return docs[0].id if docs else None


def _strip_quoted_reply(body: str) -> str:
    """Retire le message cité d'une réponse email. Ne dépend ni du client
    mail ni de la langue : le contenu cité est conventionnellement préfixé
    par '>' (coupe à la première ligne '>'), et la ligne d'amorce juste
    avant ("Untel a écrit :" / "On ... wrote:" / "Am ... schrieb:", etc.)
    se termine quasi toujours par ':', peu importe la formulation exacte."""
    kept = []
    for line in body.splitlines():
        if line.lstrip().startswith('>'):
            break
        kept.append(line)
    while kept and not kept[-1].strip():
        kept.pop()
    if kept and kept[-1].rstrip().endswith(':'):
        kept.pop()
    return '\n'.join(kept).strip()


def _fetch_and_store_emails_logic():
    """Logique commune de récupération des emails, réutilisée par le
    scheduler, la fonction HTTP et la fonction callable."""
    added_count = 0
    try:
        # Connexion à la boîte de réception
        mail = imaplib.IMAP4_SSL(IMAP_HOST, IMAP_PORT)
        mail.login(EMAIL_ADDRESS, EMAIL_PASSWORD.value)
        mail.select('inbox')
        print("Connexion réussie à la boîte de réception.")

        # Recherche des e-mails avec l'objet spécifié
        result, data = mail.search(None, 'SUBJECT', '"Vous avez un message pour la residence"')
        if result != 'OK':
            print("Erreur lors de la recherche d'e-mails.")
            return {'success': False, 'error': 'search_failed', 'added': 0}

        db = firestore.client()

        # Parcourir les e-mails trouvés
        for num in data[0].split():
            result, data = mail.fetch(num, '(RFC822)')
            if result != 'OK':
                print("Erreur lors de la récupération de l'e-mail.")
                continue

            raw_email = data[0][1]
            msg = email.message_from_bytes(raw_email)

            # Récupérer l'expéditeur, le sujet et le corps de l'e-mail
            sender = msg['From']
            regex_sender = r"<(.*?)>"
            format_sender = re.search(regex_sender, sender)
            email_format = format_sender.group(1)
            subject = msg['Subject']
            decoded_subject = ' '.join(
                part[0] if isinstance(part[0], str) else part[0].decode(part[1] or 'ascii')
                for part in decode_header(subject)
            )
            decoded_subject_no_re = re.sub(r'^\s*Re:\s*', '', decoded_subject, flags=re.IGNORECASE)

            # Date réelle de l'email (utilisée pour trier les messages côté app,
            # plus fiable que l'heure d'exécution du scheduler).
            date_header = msg['Date']
            try:
                sent_at = parsedate_to_datetime(date_header) if date_header else None
            except (TypeError, ValueError):
                sent_at = None

            final_body = None
            if msg.is_multipart():
                for part in msg.walk():
                    if part.get_content_type() == 'text/plain':
                        body = part.get_payload(decode=True).decode('utf-8')
                        final_body = _strip_quoted_reply(body)
                        break
            else:
                final_body = msg.get_payload(decode=True).decode('utf-8')

            if final_body is None:
                print(f"Corps introuvable pour l'email '{decoded_subject_no_re}', ignoré.")
                continue

            # La résidence doit être identifiable : sans residenceId, le
            # document ne serait lisible par aucune règle Firestore
            # (residences/{id}/mail est scopé par résidence).
            residence_id = resolve_residence_id(db, decoded_subject_no_re)
            if residence_id is None:
                print(f"Résidence introuvable pour le sujet '{decoded_subject_no_re}', email ignoré.")
                continue

            mail_collection = (
                db.collection('residences').document(residence_id).collection('mail')
            )

            # Stocker dans Firestore si au moins un des champs est différent
            existing_emails = mail_collection.where('message.html', '==', final_body).stream()
            if not any(doc.exists for doc in existing_emails):
                mail_collection.add({
                    'from': email_format,
                    'startTime': sent_at or firestore.SERVER_TIMESTAMP,
                    'message': {
                        'subject': decoded_subject_no_re,
                        'html': final_body
                    }
                })
                added_count += 1
                print(f"Email ajouté à Firestore (résidence {residence_id}).")

        # Déconnexion
        mail.close()
        mail.logout()
        return {'success': True, 'added': added_count}
    except Exception as e:
        print("Une erreur s'est produite lors de la connexion à la boîte de réception:", str(e))
        return {'success': False, 'error': str(e), 'added': added_count}


# ---------------------------------------------------------------------------
# Helpers - envoi (SMTP)
# ---------------------------------------------------------------------------

def _send_email_logic(to_address, subject, body, html_body=None):
    """Envoie un email via SMTP. Retourne un dict {'success': bool, 'error': str|None}."""
    if not to_address:
        return {'success': False, 'error': 'missing_recipient'}

    try:
        msg = MIMEMultipart('alternative')
        msg['From'] = EMAIL_ADDRESS
        msg['To'] = to_address
        msg['Subject'] = subject or ''

        msg.attach(MIMEText(body or '', 'plain', 'utf-8'))
        if html_body:
            msg.attach(MIMEText(html_body, 'html', 'utf-8'))

        with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT) as server:
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD.value)
            server.sendmail(EMAIL_ADDRESS, [to_address], msg.as_string())

        print(f"Email envoyé à {to_address}.")
        return {'success': True, 'error': None}
    except Exception as e:
        print("Erreur lors de l'envoi de l'email:", str(e))
        return {'success': False, 'error': str(e)}


# ---------------------------------------------------------------------------
# RÉCEPTION - planifiée (8h/10h/14h/16h/18h/20h)
# ---------------------------------------------------------------------------

@scheduler_fn.on_schedule(
    schedule="0 8,10,14,16,18,20 * * *",
    timezone="Europe/Paris",
    secrets=[EMAIL_PASSWORD]
)
def fetch_and_store_emails(event=None, context=None):
    _fetch_and_store_emails_logic()


# ---------------------------------------------------------------------------
# RÉCEPTION - immédiate, via requête HTTP
# ---------------------------------------------------------------------------

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"]),
    secrets=[EMAIL_PASSWORD]
)
def fetch_and_store_emails_http(req: https_fn.Request) -> https_fn.Response:
    result = _fetch_and_store_emails_logic()
    status_code = 200 if result.get('success') else 500
    return https_fn.Response(
        json.dumps(result),
        status=status_code,
        content_type='application/json'
    )


# ---------------------------------------------------------------------------
# RÉCEPTION - immédiate, via fonction callable (Firebase SDK côté app)
# ---------------------------------------------------------------------------

@https_fn.on_call(secrets=[EMAIL_PASSWORD])
def fetch_and_store_emails_callable(req: https_fn.CallableRequest):
    return _fetch_and_store_emails_logic()


# ---------------------------------------------------------------------------
# ENVOI - immédiat, déclenché par la création d'un document Firestore
# Ex : residences/{residenceId}/mail/{docId}
#      { "to": [...], "from": null, "message": { "subject": "...", "html": "..." } }
# ---------------------------------------------------------------------------

@firestore.transactional
def _claim_mail_for_sending(transaction, doc_ref):
    """Réserve atomiquement le document pour l'envoi : si deux invocations
    (livraison en double d'Eventarc, garantie at-least-once) lisent le
    document en même temps, seule l'une des deux transactions peut valider
    son écriture ; l'autre échoue et retente, voyant alors status='sending'
    ou 'sent' déjà posé, donc elle abandonne sans renvoyer l'email."""
    snapshot = doc_ref.get(transaction=transaction)
    data = snapshot.to_dict() or {}

    # Un message reçu par IMAP (_fetch_and_store_emails_logic) a un `from`
    # renseigné : c'est déjà un vrai email, pas besoin de le renvoyer. Seuls
    # les messages composés depuis l'app (from vide, to renseigné) doivent
    # déclencher un envoi SMTP.
    if data.get('from') is not None:
        return None
    if not data.get('to'):
        return None
    if data.get('status') in ('sending', 'sent', 'error'):
        return None

    transaction.update(doc_ref, {'status': 'sending'})
    return data


@firestore_fn.on_document_created(
    document="residences/{residenceId}/mail/{mailId}",
    secrets=[EMAIL_PASSWORD]
)
def send_email_on_create(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    snapshot = event.data
    if snapshot is None:
        return

    db = firestore.client()
    doc_ref = snapshot.reference
    data = _claim_mail_for_sending(db.transaction(), doc_ref)
    if data is None:
        return

    to_list = data.get('to') or []
    message = data.get('message') or {}
    subject = message.get('subject')
    body = message.get('html')

    results = [_send_email_logic(to_address, subject, body) for to_address in to_list]
    success = all(r['success'] for r in results)

    update_payload = {
        'status': 'sent' if success else 'error',
        'processedAt': firestore.SERVER_TIMESTAMP,
    }
    if not success:
        update_payload['error'] = next(r['error'] for r in results if not r['success'])

    doc_ref.update(update_payload)


# ---------------------------------------------------------------------------
# gerances : index de recherche par email (contacts/), régénéré automatiquement
# ---------------------------------------------------------------------------
# La recherche par email (agences/syndics) ne peut pas interroger directement
# les champs imbriqués de `services` (Firestore ne permet pas de requêter à
# l'intérieur d'un tableau/objet imbriqué avec un range query). On maintient
# donc un index plat gerances/{id}/contacts/{contactId} dérivé du champ
# `services`, jamais écrit à la main : ni l'app ni le futur backoffice n'ont
# à le tenir à jour, un seul champ (`services`) à maintenir.

@firestore_fn.on_document_written(document="gerances/{geranceId}")
def sync_gerance_contacts(event: firestore_fn.Event) -> None:
    after = event.data.after
    before = event.data.before
    doc_ref = (after or before).reference
    contacts_ref = doc_ref.collection("contacts")

    db = firestore.client()
    batch = db.batch()
    # Purge complète puis reconstruction : plus simple/sûr qu'un diff
    # incrémental pour un document modifié rarement (édition manuelle ou
    # futur backoffice, pas un flux à haut débit).
    for existing in contacts_ref.list_documents():
        batch.delete(existing)

    if after is None or not after.exists:
        batch.commit()
        return  # document gerances supprimé : on ne fait que purger l'index

    services = after.get("services") or {}
    for service_type, service in services.items():
        service = service or {}
        service_mail = service.get("mail")
        if service_mail:
            # ID auto-généré : un ID déterministe basé sur le nom du service
            # créerait un risque de collision si deux services du même type
            # existaient un jour (cf. retour explicite : éviter les doublons).
            batch.set(contacts_ref.document(), {
                "mail": service_mail,
                "phone": service.get("phone", ""),
                "serviceType": service_type,
                "agentName": None,
            })

        for agent in service.get("agents", []):
            agent_mail = agent.get("mail")
            if not agent_mail:
                continue  # agent listé par nom seulement, pas de contact direct
            full_name = f"{agent.get('name_agent', '')} {agent.get('surname_agent', '')}".strip()
            batch.set(contacts_ref.document(), {
                "mail": agent_mail,
                "phone": agent.get("phone", ""),
                "serviceType": service_type,
                "agentName": full_name,
            })

    batch.commit()


# ---------------------------------------------------------------------------
# Lot : synchronisation des données locataire dénormalisées sur User/{uid}
# après ajout/révocation (addTenant / tenant_detail.dart "Revoquer")
# ---------------------------------------------------------------------------
# firestore.rules n'autorise un propriétaire de lot (non membre du CS) qu'à
# modifier idLocataire/idLocataireOld sur residences/{id}/lots/{lotId} - jamais
# à écrire directement sur User/{uid} d'un tiers. Ce déclencheur, exécuté
# côté serveur avec les privilèges Admin (bypass firestore.rules), fait le
# nettoyage/la mise à jour dénormalisée qui échouait silencieusement
# (PermissionDeniedException) côté client, aussi bien dans
# FirestoreLotRepository._removeIdLocataireInternal (retrait) que dans
# _applyTenantChange (ajout) - même trou de permission dans les deux sens.

def _recompute_tenant_denormalization(db, uid, lot_id_just_removed=None):
    """Reconstruit User/{uid}.residencesIds et .sharedWithLandlords à partir
    de users/{uid}/lots, comme _recomputeResidencesIds/
    _recomputeSharedWithLandlords côté Dart. lot_id_just_removed, si fourni,
    est supprimé de User/{uid}/lots avant reconstruction (retrait)."""
    user_ref = db.collection("users").document(uid)

    if lot_id_just_removed is not None:
        user_ref.collection("lots").document(lot_id_just_removed).delete()

    remaining_lots = list(user_ref.collection("lots").stream())

    residence_ids = sorted({
        lot.get("residenceId") for lot in remaining_lots
        if lot.get("residenceId")
    })
    user_ref.set({"residencesIds": residence_ids}, merge=True)

    landlord_uids = set()
    for remaining_lot in remaining_lots:
        residence_id = remaining_lot.get("residenceId")
        if not residence_id:
            continue
        remote_lot = db.collection("residences").document(residence_id) \
            .collection("lots").document(remaining_lot.id).get()
        if remote_lot.exists and uid in (remote_lot.get("idLocataire") or []):
            landlord_uids.update(remote_lot.get("idProprietaire") or [])
    user_ref.set({"sharedWithLandlords": sorted(landlord_uids)}, merge=True)


@firestore_fn.on_document_written(document="residences/{residenceId}/lots/{lotId}")
def sync_lot_tenants(event: firestore_fn.Event) -> None:
    before = event.data.before
    after = event.data.after

    before_tenants = set((before.get("idLocataire") or []) if before and before.exists else [])
    after_tenants = set((after.get("idLocataire") or []) if after and after.exists else [])

    removed_tenants = before_tenants - after_tenants
    added_tenants = after_tenants - before_tenants
    if not removed_tenants and not added_tenants:
        return

    db = firestore.client()
    residence_id = event.params["residenceId"]
    lot_id = event.params["lotId"]

    for uid in removed_tenants:
        _recompute_tenant_denormalization(db, uid, lot_id_just_removed=lot_id)

    for uid in added_tenants:
        # S'assure d'abord que User/{uid}/lots/{lotId} existe (comme
        # addLotToUser côté Dart, qui échoue silencieusement pour le même
        # motif de permission quand ce n'est pas le locataire lui-même qui
        # l'appelle) : sans ce doc, le recalcul ci-dessous ne verrait pas ce
        # lot et laisserait residencesIds/sharedWithLandlords incomplets.
        db.collection("users").document(uid).collection("lots").document(lot_id).set({
            "residenceId": residence_id,
        }, merge=True)
        _recompute_tenant_denormalization(db, uid)


# ---------------------------------------------------------------------------
# residences/{id}.totalLot : compteur de lots maintenu automatiquement,
# jamais écrit depuis le client (cf. residence.dart). Incrémente/décrémente
# de façon atomique (firestore.Increment) plutôt que de recompter par une
# requête à chaque écriture : évite une lecture supplémentaire et toute
# course entre créations/suppressions concurrentes de lots.
# ---------------------------------------------------------------------------

@firestore_fn.on_document_written(document="residences/{residenceId}/lots/{lotId}")
def sync_lot_count(event: firestore_fn.Event) -> None:
    existed_before = event.data.before is not None and event.data.before.exists
    exists_after = event.data.after is not None and event.data.after.exists

    if existed_before == exists_after:
        return  # ni création ni suppression (simple mise à jour du lot)

    residence_id = event.params["residenceId"]
    delta = 1 if exists_after else -1

    firestore.client().collection("residences").document(residence_id).update({
        "totalLot": firestore.Increment(delta),
    })


# ---------------------------------------------------------------------------
# ENVOI - fallback, via requête HTTP
# Body JSON attendu : {"to": "...", "subject": "...", "body": "...", "html": "..."}
# ---------------------------------------------------------------------------

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    secrets=[EMAIL_PASSWORD]
)
def send_email_http(req: https_fn.Request) -> https_fn.Response:
    try:
        payload = req.get_json(silent=True) or {}
    except Exception:
        payload = {}

    result = _send_email_logic(
        payload.get('to'),
        payload.get('subject'),
        payload.get('body'),
        payload.get('html'),
    )
    status_code = 200 if result['success'] else 400
    return https_fn.Response(
        json.dumps(result),
        status=status_code,
        content_type='application/json'
    )


# ---------------------------------------------------------------------------
# ENVOI - fallback, via fonction callable (Firebase SDK côté app)
# Payload attendu (req.data côté app) : {"to": "...", "subject": "...", "body": "...", "html": "..."}
# ---------------------------------------------------------------------------

@https_fn.on_call(secrets=[EMAIL_PASSWORD])
def send_email_callable(req: https_fn.CallableRequest):
    data = req.data or {}
    return _send_email_logic(
        data.get('to'),
        data.get('subject'),
        data.get('body'),
        data.get('html'),
    )


# ---------------------------------------------------------------------------
# EXTRACTION IA - lecture de carte d'identité (photo_for_id.dart)
# Payload attendu (req.data côté app) :
#   { "title": "carte d'identité", "image_data_url": "data:image/jpeg;base64,..." }
# ---------------------------------------------------------------------------

@https_fn.on_call(secrets=[OPENAI_API_KEY], memory=options.MemoryOption.MB_512)
def extract_id_card_data(req: https_fn.CallableRequest):
    # Chaque appel facture des tokens OpenAI : réservé aux utilisateurs
    # connectés de l'app, pas un endpoint public.
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Authentification requise"
        )

    data = req.data or {}
    title = data.get('title')
    image_data_url = data.get('image_data_url')
    if not title or not image_data_url:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="title et image_data_url sont requis"
        )

    prompt = {
        "model": "gpt-4o",
        "messages": [
            {
                "role": "system",
                "content":
                    f""" Tu es un expert en lecture de {title}. Ne pas inventer d'informations. Si un champ est manquant ou mal lisible, indique-le comme vide.
                        Tu dois extraire : Nom, Prénom, Sexe, Nationalité, Lieu de naissance, Date de naissance.
                        Si plusieurs prénoms ou noms sont reconnus, utilise uniquement ceux les plus proches de leur champ d'origine sur la carte (ne pas mélanger).
                        les noms et les prénom ne seront jamais sur la meme ligne prend cela en considération
                        Si la nationnalité est etrangère traduit la moi en Français (ex: Venezuela => Vénézuelienne)

                        Corrige les erreurs fréquentes d'OCR :
                        - Séparation de mots collés (ex: 'JohnDoe' → 'John Doe'),
                        - Les Noms et Prénoms ne sont jamais sur la même ligne, ne les regroupent pas ensemble
                        - Correction de lettres confondues (B vs M, P vs F),
                        - Ne jamais fusionner les prénoms avec les noms ou inversement.

                        Retourne seulement un JSON propre avec les champs exacts. """
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"Voici un document de {title}. Retourne les données sous forme de JSON avec les champs attendus."
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": image_data_url}
                    }
                ]
            }
        ],
        "max_tokens": 300
    }

    response = requests.post(
        OPENAI_CHAT_COMPLETIONS_URL,
        headers={
            'Authorization': f'Bearer {OPENAI_API_KEY.value}',
            'Content-Type': 'application/json',
        },
        json=prompt,
        timeout=60,
    )

    if response.status_code != 200:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Erreur OpenAI ({response.status_code}): {response.text}"
        )

    content = response.json()['choices'][0]['message']['content']
    cleaned_content = re.sub(r'```json|```|\n', '', content)
    cleaned_content = re.sub(r'\\n|\\t', ' ', cleaned_content).strip()

    try:
        return json.loads(cleaned_content)
    except json.JSONDecodeError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Réponse OpenAI non-JSON : {e}"
        )


# ---------------------------------------------------------------------------
# APPROBATION - repasse approved à false après un rattachement self-service
# (attach_existing_lot_page.dart). Le champ `approved` est volontairement
# non-modifiable par le client dans firestore.rules (User/{uid}, allow
# update : request.resource.data.approved == resource.data.approved) : un
# nouveau rattachement de lot doit être revalidé par une personne, comme à
# l'inscription. Cette fonction est le seul moyen légitime de le faire
# depuis l'app, via le SDK Admin qui contourne les règles côté serveur.
# ---------------------------------------------------------------------------

@https_fn.on_call()
def reset_approval_after_self_attach(req: https_fn.CallableRequest):
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Authentification requise"
        )

    # Toujours l'uid de l'appelant authentifié, jamais une valeur du payload
    # client : un utilisateur ne doit pouvoir repasser en attente que son
    # propre compte.
    uid = req.auth.uid
    firestore.client().collection("users").document(uid).update({
        "approved": False,
    })
    return {"success": True}


# ---------------------------------------------------------------------------
# RAPPORT PDF - déclaration de sinistre + signalements associés
# (sinistre_tile.dart "Exporter", et lien "Télécharger le PDF" de l'email
# envoyé par send_custom_email). Ces 3 fonctions (send_custom_email,
# generate_report, trigger_report_by_url) étaient déployées à la main sur
# l'ancien projet GCP via `gcloud functions deploy` (1st gen,
# functions_framework/Flask brut), jamais via Firebase ni versionnées dans ce
# dépôt : leur source a été perdue lors de la bascule vers konodal-dev, puis
# récupérée depuis la console GCP (téléchargement du zip déployé) et adaptée
# ici au style firebase_functions/https_fn du reste de ce fichier.
# ---------------------------------------------------------------------------

REPORT_LOGO_URL = (
    "https://firebasestorage.googleapis.com/v0/b/konodal-dev.firebasestorage.app"
    "/o/assets%2Flogo%2Flogo-blanc_vertical.png?alt=media&token=91bc28f2-cca4-49f3-90bf-5e859d8d270c"
)

TRIGGER_REPORT_BY_URL_URL = "https://us-central1-konodal-dev.cloudfunctions.net/trigger_report_by_url"
GENERATE_REPORT_URL = "https://us-central1-konodal-dev.cloudfunctions.net/generate_report"


@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    secrets=[EMAIL_PASSWORD],
)
def send_custom_email(req: https_fn.Request) -> https_fn.Response:
    if req.method != "POST":
        return https_fn.Response(
            json.dumps({"error": "Méthode non autorisée"}),
            status=405,
            content_type="application/json",
        )

    data = req.get_json(silent=True) or {}
    try:
        residence_id = data["residenceId"]
        residence_name = data["residenceName"]
        residence_numero = data["residenceNumero"]
        residence_avenue = data["residenceAvenue"]
        residence_street = data["residenceStreet"]
        residence_zipcode = data["residenceZipcode"]
        residence_city = data["residenceCity"]

        post_id = data["postId"]
        post_title = data["postTitle"]
        post_img = data["postImg"]
        post_localisation = data["postLocalisation"]
        post_date = data["postDate"]
        post_description = data["postDescription"]
        declarant_status = data.get("declarantStatus", "")
        to_email = data["email"]
        subject = data["subjectMail"]
    except KeyError as e:
        return https_fn.Response(
            json.dumps({"error": f"Champ manquant : {e}"}),
            status=400,
            content_type="application/json",
        )

    url = f"{TRIGGER_REPORT_BY_URL_URL}?postId={post_id}&residenceId={residence_id}"
    residence_address = f"{residence_numero} {residence_avenue} {residence_street}"
    residence_zipcity = f"{residence_zipcode} {residence_city}"
    declarant_html = (
        f'<p><strong>Déclarant :</strong> {declarant_status}</p>' if declarant_status else ''
    )

    html = f"""
    <!DOCTYPE html>
    <html lang="fr">
    <head>
    <meta charset="UTF-8">
    <title>KONODAL - Notification</title>
    </head>
    <body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <table align="center" width="600" style="background-color: #ffffff; border-collapse: collapse; margin-top: 20px;">
        <!-- Header -->
        <tr>
        <td style="background-color: #48775B; color: white; text-align: center; padding: 30px 20px;">
            <img src="{REPORT_LOGO_URL}" alt="KONODAL-Logo" width="250" style="max-width: 100%;" />
            <p style="margin: 5px 0 0;font-size: 16px">Déclaration de sinistre</p>
        </td>
        </tr>

        <!-- Body -->
        <tr>
        <td style="padding: 20px 20px; color: #333333;">
            <div style="text-align: center;">
                <p>Un résident a déclaré un nouveau sinistre dans la résidence :</p>
                <h2>{residence_name}</h2>
                <p>{residence_address}<br>{residence_zipcity}</p>
            </div>

            <p style="font-size: 16px; text-align: center; margin-top: 20px;"><strong>Intitulé : {post_title}</strong></p>
            {declarant_html}
            <div style="text-align: center; margin: 20px 0;">
                <img src="{post_img}" alt="Illustration Sinistre" width="400" style="max-width: 100%; border-radius: 8px;" />
            </div>
            <p><strong>Localisation :</strong> {post_localisation}</p>
            <p><strong>Date de publication :</strong> {post_date}</p>
            <p><strong>Description de l'incident :</strong><br>
            {post_description}
            </p>

        <!-- Call to Action -->
        <div style="margin: 30px 0; text-align: center;">
            <p style="margin: 5px 0;">Pour plus d'informations</p>
            <a href="{url}" style="background-color: #48775B; color: white; padding: 8px 16px; text-decoration: none; border-radius: 6px; display: inline-block;">
                Télécharger le PDF
            </a>
        </div>
        <p style="font-size: 12px; color: #666; text-align: center;">
            En cas de difficultés, merci de contacter nos services via :
            <a href="mailto:support@connectkasa.com" style="color: #48775B; font-size: 12px;">
                support@connectkasa.com
            </a>
        </p>
        </td>
        </tr>

        <!-- Footer -->
        <tr>
        <td style="background-color: #e0e0e0; text-align: center; padding: 20px;">
            <p style="margin: 10px 0;">KONODAL</p>
            <div style="margin: 10px 0;">
            <a href="#"><img src="https://cdn-icons-png.flaticon.com/24/2111/2111463.png" alt="Instagram" style="margin: 0 5px;"></a>
            <a href="#"><img src="https://cdn-icons-png.flaticon.com/24/2111/2111748.png" alt="YouTube" style="margin: 0 5px;"></a>
            <a href="#"><img src="https://cdn-icons-png.flaticon.com/24/2111/2111532.png" alt="LinkedIn" style="margin: 0 5px;"></a>
            </div>
            <p style="font-size: 12px; color: #777;">Copyright © 2023</p>
        </td>
        </tr>
    </table>
    </body>
    </html>
    """

    try:
        message = MIMEMultipart("alternative")
        message["Subject"] = subject
        message["From"] = EMAIL_ADDRESS
        message["To"] = to_email
        message.attach(MIMEText(html, "html"))

        with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT) as server:
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD.value)
            server.sendmail(EMAIL_ADDRESS, to_email, message.as_string())

        return https_fn.Response(
            json.dumps({"success": True, "message": "Email envoyé"}),
            status=200,
            content_type="application/json",
        )
    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            content_type="application/json",
        )


class _ReportGenerator:
    """Génère le PDF de déclaration (Post + signalements) pour une résidence."""

    @staticmethod
    def fetch_post_and_signalements(db, residence_id, post_id):
        """Récupère les informations du Post (via champ 'id') et des Signalements associés"""
        posts_ref = db.collection("residences").document(residence_id).collection("posts")
        query = posts_ref.where("id", "==", post_id).stream()

        for post_doc in query:
            post_data = post_doc.to_dict()

            signalements_ref = post_doc.reference.collection("signalements")
            signalements_docs = signalements_ref.stream()
            residence_data = _ReportGenerator.get_residence_data(db, residence_id)
            post_data["residence"] = residence_data
            residenceid = residence_data.get("id", "") if residence_data else ""
            user_data = _ReportGenerator.get_user_data(db, post_data["user"], residenceid)

            signalements = []
            for sig_doc in signalements_docs:
                sig_data = sig_doc.to_dict()
                sig_user_data = _ReportGenerator.get_user_data(db, sig_data["user"], residenceid)
                sig_data["user_data"] = sig_user_data
                signalements.append(sig_data)

            post_data["user_data"] = user_data

            return post_data, signalements, len(signalements)

        # Aucun post trouvé
        return None, [], 0

    @staticmethod
    def get_residence_data(db, residence_id):
        """Récupère les données de la résidence à partir de Firestore"""
        residence_doc = db.collection("residences").document(residence_id).get()
        return residence_doc.to_dict() if residence_doc.exists else None

    @staticmethod
    def get_user_data(db, user_id, residence_id):
        """Récupère les données de l'utilisateur ainsi que le premier lot lié à la résidence"""
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            return None

        user_data = user_doc.to_dict()

        # Trouve le premier lot dont le champ residenceId correspond à
        # residence_id. L'ID du document de lot n'a plus de rapport avec
        # residence_id depuis le passage à un ID de lot indépendant (composite
        # "{residenceId}-{refLot}" abandonné) : matcher sur l'ID du document
        # (startswith) ne trouverait donc plus jamais rien.
        for lot_doc in user_ref.collection("lots").stream():
            lot_data = lot_doc.to_dict()
            if lot_data.get("residenceId") == residence_id:
                user_data["lot_data"] = lot_data
                break

        return user_data

    @staticmethod
    def generate_pdf(structured_data):
        """Crée un PDF temporaire à partir des données avec pagination et images"""
        tmpfile = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf")
        c = canvas.Canvas(tmpfile.name, pagesize=A4)
        width, height = A4
        margin = 2 * cm
        y = height - margin
        min_y = margin
        space_header = 0.8
        space_para = 0.4

        def draw_line(text, indent=0, font_size=11, color=(0, 0, 0), advance=True):
            nonlocal y
            c.setFont("Helvetica", font_size)
            c.setFillColorRGB(*color)

            text_width = c.stringWidth(text)
            available_width = width - margin - indent * cm

            if text_width > available_width:
                words = text.split(' ')
                line = ""
                for word in words:
                    test_line = f"{line} {word}".strip()
                    if c.stringWidth(test_line) <= available_width:
                        line = test_line
                    else:
                        c.drawString(margin + indent * cm, y, line)
                        if advance:
                            y -= space_para * cm
                            if y < min_y:
                                draw_footer()
                                c.showPage()
                                y = height - margin
                        line = word

                if line:
                    c.drawString(margin + indent * cm, y, line)
                    if advance:
                        y -= space_para * cm
            else:
                c.drawString(margin + indent * cm, y, text)
                if advance:
                    y -= space_para * cm
            if y < min_y:
                draw_footer()
                c.showPage()
                y = height - margin

        def draw_header(text, font_size, color, is_centered=False, is_bold=False, is_italic=False):
            nonlocal y
            c.setFont("Helvetica-Bold" if is_bold else "Helvetica-Oblique" if is_italic else "Helvetica", font_size)
            c.setFillColorRGB(*color)

            text_width = c.stringWidth(text)
            x_position = (width - text_width) / 2 if is_centered else margin
            c.drawString(x_position, y, text)
            y -= 0.1 * cm

        def draw_spacer(space=0.4):
            nonlocal y
            y -= space * cm

        def draw_logo_url(url, max_width=6 * cm, max_height=1 * cm):
            nonlocal y

            try:
                response = requests.get(url)
                response.raise_for_status()
                image = ImageReader(BytesIO(response.content))
                iw, ih = image.getSize()

                scale = min(max_width / iw, max_height / ih)
                w, h = iw * scale, ih * scale

                if y - h < min_y:
                    draw_footer()
                    c.showPage()
                    y = height - margin

                c.drawImage(image, margin - 1 * cm, y - (h - 1 * cm), width=w, height=h)
                y -= h + 0.1 * cm

            except requests.exceptions.RequestException as e:
                draw_line(f"[Erreur de chargement image: {e}]", indent=1)

        def draw_image_from_url(url, max_width=15 * cm, max_height=8 * cm):
            nonlocal y
            try:
                response = requests.get(url)
                response.raise_for_status()
                image = ImageReader(BytesIO(response.content))

                if y - max_height < min_y:
                    draw_footer()
                    c.showPage()
                    y = height - margin

                c.drawImage(
                    image,
                    margin,
                    y - max_height,
                    width=max_width,
                    height=max_height,
                    mask='auto',
                    preserveAspectRatio=False,
                    anchor='c',
                    anchorAtXY=False
                )

                y -= max_height + 0.1 * cm

            except requests.exceptions.RequestException as e:
                draw_line(f"[Erreur de chargement image: {e}]", indent=1)

        def draw_footer():
            footer_text = "Contact : contact@connectkasa.fr | www.connectkasa.fr"
            footer_divider = "_" * 100

            footer_y = margin / 2
            divider_y = footer_y + 15

            c.setFont("Helvetica", 10)
            c.setFillColorRGB(0.8, 0.8, 0.8)
            c.drawCentredString(width / 2, divider_y, footer_divider)

            c.setFont("Helvetica-Oblique", 9)
            c.setFillColorRGB(0.5, 0.5, 0.5)
            page_num = c.getPageNumber()
            c.drawRightString(width - margin, margin / 2, f"Page {page_num}")
            c.drawCentredString(width / 2, footer_y, footer_text)

        def format_date(timestamp):
            """Formate le timestamp au format 'dd/mm/yyyy à hh:mm'"""
            try:
                dt = timestamp.replace(tzinfo=None) if isinstance(timestamp, datetime) else datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S.%f")
                return dt.strftime("%d/%m/%Y à %H:%M")
            except Exception:
                return "Date format error"

        declared_timestamp = structured_data[0]["data"].get("declaredDate")
        formatted_declared_timestamp = format_date(declared_timestamp)
        post_timestamp = structured_data[0]["data"].get("timeStamp")
        formatted_post_timestamp = format_date(post_timestamp)

        # === DÉBUT DU CADRE VERT ===
        start_y = y

        residence_data = structured_data[0]["data"].get('residence', {}) or {}

        buffer_lines = []
        post_data = structured_data[0]["data"]

        def buffer_draw(func, *args, **kwargs):
            buffer_lines.append((func, args, kwargs))
            func(*args, **kwargs)

        buffer_draw(draw_logo_url, REPORT_LOGO_URL)
        y -= 2 * cm
        buffer_draw(draw_header, "Déclaration d'incident", 25, (1, 1, 1), True, True)

        draw_spacer(space_header)
        buffer_draw(draw_header, "Pour", 14, (1, 1, 1), True)
        draw_spacer(space_header)

        if residence_data:
            buffer_draw(draw_header, residence_data.get('name', ''), 16, (1, 1, 1), True, True)
            draw_spacer(space_para)

            residence_address = residence_data.get('address') or {}
            address_line = f"{residence_address.get('numero', '')} {residence_address.get('avenue', '')} {residence_address.get('street', '')}"
            buffer_draw(draw_header, address_line.strip(), 14, (1, 1, 1), True, False, True)
            draw_spacer(space_para)

            city_line = f"{residence_address.get('zipCode', '')} {residence_address.get('city', '')}"
            buffer_draw(draw_header, city_line.strip(), 14, (1, 1, 1), True, False, True)

        end_y = y

        rect_height = start_y + 2 * cm - end_y

        c.setFillColorRGB(72 / 255, 119 / 255, 91 / 255)
        c.rect(margin - 2 * cm, end_y, width * margin, rect_height, stroke=0, fill=1)

        y = start_y
        for func, args, kwargs in buffer_lines:
            func(*args, **kwargs)
            draw_spacer(space_header)

        draw_spacer(1)
        # === Tableau d'informations supplémentaires ===

        title = post_data.get("title", "")
        total_signalements = structured_data[0].get("total_signalements", 0)
        col1_x = margin
        col2_x = width / 2 + margin / 2
        row_height = 0.8 * cm

        def draw_table_row(row_y, label, value):
            c.setFont("Helvetica-Bold", 12)
            c.setFillColorRGB(0, 0, 0)
            c.drawString(col1_x, row_y, label)
            c.setFont("Helvetica", 12)
            c.drawString(col2_x, row_y, value)

        row1_y = y
        row2_y = y - row_height
        row3_y = y - 2 * row_height

        draw_table_row(row1_y, "Intitulé :", title)
        draw_table_row(row2_y, "Date de la déclaration :", formatted_declared_timestamp)
        draw_table_row(row3_y, "Nombre de signalements :", str(total_signalements))

        y = row3_y - row_height
        draw_header("_" * 60, font_size=16, color=(0.80, 0.80, 0.80), is_centered=True)
        draw_spacer(1)
        draw_header("Signalement N°1 :", font_size=14, color=(72 / 255, 119 / 255, 91 / 255), is_bold=True)
        draw_spacer(space_header)
        draw_header(f"   Référence signalement : {post_data.get('id')}", font_size=12, color=(0, 0, 0))
        draw_spacer(space_header)
        draw_header("Information sur le déclarant :", font_size=14, color=(0, 0, 0), is_bold=True)
        draw_spacer(space_header)
        user_info = post_data.get("user_data") or {}
        name = user_info.get("name", "Inconnu")
        surname = user_info.get("surname", "Inconnu")
        draw_header(f"   Nom : {name} {surname}", font_size=12, color=(0, 0, 0))
        draw_spacer(space_para)
        lot_info = user_info.get("lot_data") or {}
        statut = lot_info.get("StatutResident", "Non renseigné")
        draw_header(f"   Statut déclarant : {statut}", font_size=12, color=(0, 0, 0))
        draw_spacer(space_header)

        post_img_url = structured_data[0]["data"].get("pathImage")
        if post_img_url:
            draw_image_from_url(post_img_url)
        draw_spacer(space_header)

        location = post_data.get('location_element', '')
        floor = post_data.get('location_floor', '')
        location_details = ', '.join(post_data.get('location_details') or [])
        draw_header(f"Localisation : {location} • Etage : {floor} • Précision : {location_details}", font_size=12, color=(0, 0, 0))
        draw_spacer(space_para)
        draw_header(f"Date de publication: {formatted_post_timestamp}", font_size=12, color=(0, 0, 0))
        draw_spacer(space_header)

        description = post_data.get("description", "")
        draw_header("Description de l'incident: ", font_size=12, color=(0, 0, 0))
        draw_spacer(space_para + 0.2)
        draw_line(f"{description}", font_size=12, color=(0, 0, 0))
        draw_spacer(space_header)

        if structured_data[0].get("signalements"):
            draw_header("_" * 100, font_size=10, color=(0.80, 0.80, 0.80), is_centered=True)
            i = 1
            for sig in structured_data[0]["signalements"]:
                draw_spacer(1)
                i += 1
                sig_timestamp = sig.get("timeStamp")
                formatted_sig_timestamp = format_date(sig_timestamp)
                draw_header(f"Signalement N°{i} :", font_size=14, color=(72 / 255, 119 / 255, 91 / 255), is_bold=True)
                draw_spacer(space_header)
                draw_header(f"   Référence signalement : {sig.get('id')}", font_size=12, color=(0, 0, 0))
                draw_spacer(space_header)
                draw_header("Information sur le déclarant :", font_size=14, color=(0, 0, 0), is_bold=True)
                draw_spacer(space_header)
                user_sig_info = sig.get("user_data") or {}
                name = user_sig_info.get("name", "Inconnu")
                surname = user_sig_info.get("surname", "Inconnu")
                draw_header(f"   Nom : {name} {surname}", font_size=12, color=(0, 0, 0))
                draw_spacer(space_para)
                lot_info = user_sig_info.get("lot_data") or {}
                statut = lot_info.get("StatutResident", "Non renseigné")
                draw_header(f"   Statut déclarant : {statut}", font_size=12, color=(0, 0, 0))
                draw_spacer(space_header)
                sig_image_url = sig.get("pathImage")
                if sig_image_url:
                    draw_image_from_url(sig_image_url)
                    draw_spacer(space_para)

                y -= 0.6 * cm

                sig_location_details = ', '.join(sig.get('location_details') or [])
                draw_header(f"Localisation : {sig.get('location_element', '')} • Etage : {sig.get('location_floor', '')} • Précision : {sig_location_details}", font_size=12, color=(0, 0, 0))
                draw_spacer(space_para)
                draw_header(f"Date de publication: {formatted_sig_timestamp}", font_size=12, color=(0, 0, 0))
                draw_spacer(space_header)
                draw_header("Description de l'incident :", font_size=12, color=(0, 0, 0))
                draw_spacer(space_para + 0.2)
                draw_line(f"   {sig.get('description', '')}", font_size=12, color=(0, 0, 0))
                draw_spacer(space_header)

        draw_footer()
        c.save()
        return tmpfile.name


@https_fn.on_request(cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]))
def generate_report(req: https_fn.Request) -> https_fn.Response:
    """Génère le PDF de déclaration pour un Post donné (postId + residenceId)."""
    payload = req.get_json(silent=True) or {}
    post_id = payload.get("postId")
    residence_id = payload.get("residenceId")

    if not post_id or not residence_id:
        return https_fn.Response(
            json.dumps({"error": "Missing 'postId' or 'residenceId'"}),
            status=400,
            content_type="application/json",
        )

    db = firestore.client()
    try:
        post_data, signalements, total_signalements = _ReportGenerator.fetch_post_and_signalements(
            db, residence_id, post_id
        )
        if post_data is None:
            return https_fn.Response(
                json.dumps({"error": "Post not found."}),
                status=404,
                content_type="application/json",
            )

        structured_data = [{
            "type": "Post",
            "data": post_data,
            "signalements": signalements,
            "total_signalements": total_signalements + 1,
        }]

        pdf_path = _ReportGenerator.generate_pdf(structured_data)
        try:
            with open(pdf_path, "rb") as f:
                pdf_bytes = f.read()
        finally:
            os.remove(pdf_path)

        return https_fn.Response(
            pdf_bytes,
            status=200,
            content_type="application/pdf",
            headers={"Content-Disposition": "attachment; filename=rapport_signalements.pdf"},
        )

    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            content_type="application/json",
        )


@https_fn.on_request(cors=options.CorsOptions(cors_origins="*", cors_methods=["get"]))
def trigger_report_by_url(req: https_fn.Request) -> https_fn.Response:
    """Point d'entrée GET (lien cliquable depuis l'email) qui proxifie vers
    generate_report (POST) et renvoie directement le PDF."""
    post_id = req.args.get("postId")
    residence_id = req.args.get("residenceId")

    if not post_id or not residence_id:
        return https_fn.Response(
            json.dumps({"error": "Paramètres manquants"}),
            status=400,
            content_type="application/json",
        )

    try:
        response = requests.post(
            GENERATE_REPORT_URL,
            json={"postId": post_id, "residenceId": residence_id},
        )

        if response.status_code != 200:
            return https_fn.Response(
                f"<h3>Erreur lors de la génération du rapport.</h3><p>{response.text}</p>",
                status=500,
                content_type="text/html",
            )

        if response.headers.get("Content-Type") == "application/pdf":
            return https_fn.Response(
                response.content,
                status=200,
                content_type="application/pdf",
                headers={
                    "Content-Disposition": f"inline; filename=rapport_{residence_id}_{post_id}.pdf"
                },
            )

        try:
            pdf_url = response.json().get("url")
        except ValueError:
            pdf_url = None
        if pdf_url:
            return https_fn.Response(status=302, headers={"Location": pdf_url})

        return https_fn.Response(
            "<h3>Rapport généré avec succès.</h3>",
            status=200,
            content_type="text/html",
        )

    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            content_type="application/json",
        )


# ---------------------------------------------------------------------------
# DÉTECTION DE DOUBLON - sinistre similaire déjà signalé dans les 24h
# (submit_post_controller.dart, avant création d'un post de type sinistre).
# Même origine que les 3 fonctions ci-dessus (récupérée depuis l'ancien projet
# GCP, jamais versionnée) : adaptée ici au style https_fn, et convertie pour
# réutiliser OPENAI_API_KEY/requests (comme extract_id_card_data) plutôt que
# le package `openai` de l'original - évite d'ajouter cette dépendance en plus
# de numpy/pytz alors que le reste du fichier n'en a pas besoin (similarité
# cosinus calculable en pur Python, `timezone.utc` remplace pytz).
# ---------------------------------------------------------------------------

OPENAI_EMBEDDINGS_URL = 'https://api.openai.com/v1/embeddings'

_DUPLICATE_CHECK_STOPWORDS_FR = frozenset([
    "le", "la", "les", "un", "une", "des", "du", "de", "d", "au", "aux", "à", "dans", "par", "pour",
    "en", "vers", "avec", "chez", "sur", "sous", "entre", "contre", "sans", "après", "avant", "près", "loin",
    "depuis", "je", "tu", "il", "elle", "on", "nous", "vous", "ils", "elles", "lui", "leur", "moi", "toi", "se",
    "ce", "cela", "ça", "qui", "que", "quoi", "être", "avoir", "fait", "fais", "doit", "peut", "et", "ou", "mais",
    "donc", "or", "ni", "car", "lorsque", "quand", "comme", "puisque", "si", "notre", "votre", "leur", "mon", "ton",
    "ma", "ta", "mes", "tes", "ses", "nos", "vos", "leurs", "même", "autre", "quel", "quelle", "quels", "quelles",
    "truc", "chose", "genre", "type", "cas", "situation",
])


def _get_text_embedding(text):
    if not text:
        return [0.0] * 1536
    try:
        response = requests.post(
            OPENAI_EMBEDDINGS_URL,
            headers={
                'Authorization': f'Bearer {OPENAI_API_KEY.value}',
                'Content-Type': 'application/json',
            },
            json={'model': 'text-embedding-3-small', 'input': text},
            timeout=30,
        )
        response.raise_for_status()
        return response.json()['data'][0]['embedding']
    except Exception as e:
        print(f"Erreur lors de la génération de l'embedding : {e}")
        return [0.0] * 1536


def _cosine_similarity(vec1, vec2):
    norm1 = sum(v * v for v in vec1) ** 0.5
    norm2 = sum(v * v for v in vec2) ** 0.5
    if norm1 == 0 or norm2 == 0:
        return 0
    dot = sum(a * b for a, b in zip(vec1, vec2))
    return dot / (norm1 * norm2)


def _normalize_text(text):
    if not text:
        return ""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s]", "", text)
    text = re.sub(r"\s+", " ", text)
    return text


def _extract_keywords(text):
    words = re.findall(r'\b\w{3,}\b', text.lower())
    return [word for word in words if word not in _DUPLICATE_CHECK_STOPWORDS_FR]


def _keyword_overlap(kw1, kw2):
    if not kw1 or not kw2:
        return 0
    set1, set2 = set(kw1), set(kw2)
    return len(set1 & set2) / max(len(set1), 1)


@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    secrets=[OPENAI_API_KEY],
)
def check_similar_post_OpenAI(req: https_fn.Request) -> https_fn.Response:
    if req.method != 'POST':
        return https_fn.Response('Method Not Allowed', status=405)

    data = req.get_json(silent=True)
    if not data or "params" not in data:
        return https_fn.Response('Bad Request', status=400)

    params = data["params"]
    doc_res = params.get("docRes")
    post_id = params.get("postId")
    title = params.get("title", "")
    description = params.get("description", "")
    location_element = params.get("location_element", "")
    location_floor = params.get("location_floor", "")

    if not doc_res or not post_id or not title or not description:
        return https_fn.Response('Bad Request', status=400)

    title_norm = _normalize_text(title)
    description_norm = _normalize_text(description)
    location_element_norm = _normalize_text(location_element)
    location_floor_norm = _normalize_text(location_floor)

    title_embed = _get_text_embedding(title_norm)
    desc_embed = _get_text_embedding(description_norm)
    keywords_new = _extract_keywords(f"{title_norm} {description_norm}")

    db = firestore.client()
    twenty_four_hours_ago = datetime.now(timezone.utc) - timedelta(hours=24)

    posts_ref = db.collection("residences").document(doc_res).collection("posts").where("type", "==", "sinistres")

    for doc in posts_ref.stream():
        existing = doc.to_dict()
        existing_id = doc.id

        if not existing.get('timeStamp') or existing['timeStamp'] < twenty_four_hours_ago:
            continue

        if _normalize_text(existing.get("location_element", "")) != location_element_norm:
            continue
        if _normalize_text(existing.get("location_floor", "")) != location_floor_norm:
            continue

        existing_title = _normalize_text(existing.get("title", ""))
        existing_desc = _normalize_text(existing.get("description", ""))

        existing_title_embed = _get_text_embedding(existing_title)
        existing_desc_embed = _get_text_embedding(existing_desc)
        keywords_existing = _extract_keywords(f"{existing_title} {existing_desc}")

        sim_title = _cosine_similarity(title_embed, existing_title_embed)
        sim_desc = _cosine_similarity(desc_embed, existing_desc_embed)
        sim_kw = _keyword_overlap(keywords_new, keywords_existing)

        if sim_title > 0.5 and sim_desc > 0.5 and sim_kw >= 0.2:
            return https_fn.Response(
                json.dumps({
                    "status": "duplicate_found",
                    "post_id": existing_id,
                    "similarity_score": {
                        "title": round(sim_title, 3),
                        "description": round(sim_desc, 3),
                        "keywords": round(sim_kw, 3),
                    },
                }),
                status=200,
                content_type='application/json',
            )

    return https_fn.Response(
        json.dumps({
            "status": "new_post_created",
            "message": "No duplicates found",
        }),
        status=200,
        content_type='application/json',
    )
