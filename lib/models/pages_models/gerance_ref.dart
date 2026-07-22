/// Référence vers un contact gerances (résidence/bâtiment/lot référencé dans
/// l'annuaire gerances), par opposition à un Agency embarqué localement quand
/// aucun match n'est trouvé (agence/syndic hors référentiel).
class GeranceRef {
  final String geranceId;
  final String serviceType; // "serviceSyndic", "geranceLocative", ...
  final String? agentUid; // uid de l'agent précis choisi, si choisi

  GeranceRef({
    required this.geranceId,
    required this.serviceType,
    this.agentUid,
  });

  factory GeranceRef.fromJson(Map<String, dynamic> json) {
    return GeranceRef(
      geranceId: json['geranceId'] ?? '',
      serviceType: json['serviceType'] ?? '',
      agentUid: json['agentUid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'geranceId': geranceId,
      'serviceType': serviceType,
      if (agentUid != null) 'agentUid': agentUid,
    };
  }
}
