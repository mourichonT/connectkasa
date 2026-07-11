import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;

/// Remplace print()/debugPrint() (dette technique P4) : n'affiche rien
/// hors kDebugMode (silencieux en release), utilise dart:developer.log
/// au lieu de print() - pas de troncature à 1024 caractères, intégration
/// DevTools, et un `error`/`stackTrace` structurés plutôt qu'interpolés
/// dans le message.
void appLog(Object? message, {Object? error, StackTrace? stackTrace}) {
  if (kDebugMode) {
    developer.log('$message', error: error, stackTrace: stackTrace);
  }
}
