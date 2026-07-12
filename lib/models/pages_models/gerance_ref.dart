/// Référence vers un contact gerances (résidence/bâtiment/lot référencé dans
/// l'annuaire gerances), par opposition à un Agency embarqué localement quand
/// aucun match n'est trouvé (agence/syndic hors référentiel).
class GeranceRef {
  final String geranceId;
  final String serviceType; // "serviceSyndic", "geranceLocative", ...
  final String? agentMail; // contact direct d'un agent précis, si choisi

  GeranceRef({
    required this.geranceId,
    required this.serviceType,
    this.agentMail,
  });

  factory GeranceRef.fromJson(Map<String, dynamic> json) {
    return GeranceRef(
      geranceId: json['geranceId'] ?? '',
      serviceType: json['serviceType'] ?? '',
      agentMail: json['agentMail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'geranceId': geranceId,
      'serviceType': serviceType,
      if (agentMail != null) 'agentMail': agentMail,
    };
  }
}
