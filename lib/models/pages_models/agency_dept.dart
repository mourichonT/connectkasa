class Agent {
  final String nameAgent;
  final String surnameAgent;
  final String? mail; // contact direct de l'agent, si l'agence le permet
  final String? phone;
  final String? uid; // uid users/{uid} - null pour une agence custom non référencée

  Agent({
    required this.nameAgent,
    required this.surnameAgent,
    this.mail,
    this.phone,
    this.uid,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      nameAgent: json['name_agent'] ?? '',
      surnameAgent: json['surname_agent'] ?? '',
      mail: json['mail'],
      phone: json['phone'],
      uid: json['uid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_agent': nameAgent,
      'surname_agent': surnameAgent,
      if (mail != null) 'mail': mail,
      if (phone != null) 'phone': phone,
      if (uid != null) 'uid': uid,
    };
  }
}

class AgencyDept {
  final List<Agent> agents;
  final String mail;
  final String phone;

  AgencyDept({
    required this.agents,
    required this.mail,
    required this.phone,
  });

  factory AgencyDept.fromJson(Map<String, dynamic> json) {
    var agentsJson = json['agents'] as List<dynamic>? ?? [];
    List<Agent> agentsList = agentsJson
        .map((agentJson) => Agent.fromJson(agentJson as Map<String, dynamic>))
        .toList();

    return AgencyDept(
      agents: agentsList,
      mail: json['mail'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agents': agents.map((agent) => agent.toJson()).toList(),
      'mail': mail,
      'phone': phone,
    };
  }
}
