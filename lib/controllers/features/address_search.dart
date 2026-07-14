import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/models/pages_models/ban_address_suggestion.dart';

/// Recherche d'adresses via l'API Adresse (api-adresse.data.gouv.fr) - le
/// service public officiel de géocodage en France (Etalab/IGN), gratuit et
/// sans clé API. Utilisé pour éviter les adresses saisies librement/
/// invalides dans les dossiers locataire et garant.
class AddressSearch {
  /// [type] filtre la nature des résultats ("street" pour ne suggérer que
  /// des voies, sans exiger de numéro déjà saisi - cf. api-adresse.data.gouv.fr
  /// pour les valeurs possibles : housenumber, street, locality, municipality).
  static Future<List<BanAddressSuggestion>> search(String query,
      {String? type}) async {
    if (query.trim().length < 3) return [];

    final uri = Uri.https('api-adresse.data.gouv.fr', '/search/', {
      'q': query,
      'limit': '5',
      if (type != null) 'type': type,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (data['features'] as List<dynamic>?) ?? [];
      return features
          .map((feature) =>
              BanAddressSuggestion.fromFeature(feature as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLog("Erreur lors de la recherche d'adresse (API Adresse) : $e");
      return [];
    }
  }
}
