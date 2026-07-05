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
        db.collection('Residence')
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
            # (Residence/{id}/mail est scopé par résidence).
            residence_id = resolve_residence_id(db, decoded_subject_no_re)
            if residence_id is None:
                print(f"Résidence introuvable pour le sujet '{decoded_subject_no_re}', email ignoré.")
                continue

            mail_collection = (
                db.collection('Residence').document(residence_id).collection('mail')
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
# Ex : Residence/{residenceId}/mail/{docId}
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
    document="Residence/{residenceId}/mail/{mailId}",
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
# Gerance : index de recherche par email (contacts/), régénéré automatiquement
# ---------------------------------------------------------------------------
# La recherche par email (agences/syndics) ne peut pas interroger directement
# les champs imbriqués de `services` (Firestore ne permet pas de requêter à
# l'intérieur d'un tableau/objet imbriqué avec un range query). On maintient
# donc un index plat Gerance/{id}/contacts/{contactId} dérivé du champ
# `services`, jamais écrit à la main : ni l'app ni le futur backoffice n'ont
# à le tenir à jour, un seul champ (`services`) à maintenir.

@firestore_fn.on_document_written(document="Gerance/{geranceId}")
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
        return  # document Gerance supprimé : on ne fait que purger l'index

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
