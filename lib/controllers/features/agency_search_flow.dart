import 'package:connect_kasa/core/repositories/agency_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_agency_repository.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';
import 'package:connect_kasa/models/pages_models/gerance_ref.dart';

/// Mutualise le flux "chercher une agence/syndic par email -> sélectionner
/// un match référencé dans Gerance, ou saisir une entrée custom si aucun
/// match" utilisé par les 3 écrans d'affectation (résidence, bâtiment, lot).
/// Un seul endroit à corriger/faire évoluer plutôt que 3 copies du même code.
class AgencySearchFlow {
  final String serviceType; // "serviceSyndic" ou "geranceLocative"
  final IAgencyRepository _repository;

  AgencySearchFlow({
    required this.serviceType,
    IAgencyRepository? repository,
  }) : _repository = repository ?? FirestoreAgencyRepository();

  Future<List<Agency>> search(String emailPart) async {
    final result =
        await _repository.searchByEmail(emailPart, serviceType: serviceType);
    return result.when(success: (agencies) => agencies, failure: (_) => []);
  }

  Future<Agency?> resolve(GeranceRef ref) async {
    final result = await _repository.resolveRef(ref);
    return result.when(success: (agency) => agency, failure: (_) => null);
  }

  /// Entrée locale, non référencée dans Gerance (aucun match trouvé).
  Agency buildCustomAgency(String emailPart) => Agency(
        id: '',
        name: emailPart,
        city: '',
        numeros: '',
        street: '',
        voie: '',
        zipCode: '',
        syndic: AgencyDept(agents: [], mail: emailPart, phone: ''),
      );

  /// null si `agency` est une entrée custom (id vide, jamais trouvée dans
  /// Gerance) : peut arriver même via onSelect, car l'entrée custom est
  /// affichée dans la même liste cliquable que les vrais matchs Gerance.
  GeranceRef? refFor(Agency agency, {String? agentMail}) {
    if (agency.id.isEmpty) return null;
    return GeranceRef(
      geranceId: agency.id,
      serviceType: serviceType,
      agentMail: agentMail,
    );
  }
}
