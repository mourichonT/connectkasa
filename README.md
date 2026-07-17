# Konodal

Application Flutter de gestion de résidence (copropriété/syndic) : annonces entre voisins,
signalements, messagerie, documents, contacts, gestion locative. Backend Firebase
(Firestore, Auth, Storage, Cloud Functions).

## Architecture Firestore

Le contenu est cloisonné par résidence : un utilisateur peut appartenir à plusieurs
résidences, et tout le contenu (posts, chat, mail, documents, lots, événements) est
scopé sous `Residence/{residenceId}/...`. Voir `firestore.rules` pour le détail des
permissions par sous-collection.

## Cloud Functions

Le projet Firebase héberge deux codebases distinctes (voir `firebase.json`) :

- **`default`** (`functions/`, Node.js) : notifications (nouveau post, nouveau message,
  demande de location), purge de compte, détection IA de doublons de signalements.
- **`mail`** (`functions_python/`, Python) : réception des emails entrants par IMAP
  (`fetch_and_store_emails`, planifiée) et envoi réel des messages écrits depuis le
  chat mail de l'app par SMTP (`send_email_on_create`, déclenchée à la création d'un
  document dans `Residence/{id}/mail`).

### Déployer les fonctions Node (`functions/`)

```
firebase deploy --only functions:default
```

### Déployer les fonctions Python (`functions_python/`)

Nécessite un environnement virtuel local (la CLI Firebase l'utilise pour analyser
le code avant l'upload, elle ne le crée pas elle-même) :

```
cd functions_python
python -m venv venv
venv/Scripts/python.exe -m pip install -r requirements.txt   # Scripts/ sous Windows, bin/ sous Unix
cd ..
firebase deploy --only functions:mail
```

Le secret `EMAIL_PASSWORD` (mot de passe d'application Gmail, pas le mot de passe du
compte) doit être défini avant le premier déploiement :

```
firebase functions:secrets:set EMAIL_PASSWORD
```

### Règles et index Firestore

```
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## Démarrer le projet Flutter

Ce projet est une application Flutter standard :

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Documentation Flutter](https://docs.flutter.dev/)
