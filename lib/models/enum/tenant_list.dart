class TenantList {
  /// Basé sur la table "Nature du contrat" de la norme DSN (Déclaration
  /// Sociale Nominative), le référentiel officiel commun à l'URSSAF et aux
  /// autres organismes sociaux (Pôle emploi/France Travail, retraite
  /// complémentaire...) pour qualifier un contrat de travail, complété par
  /// les statuts hors salariat classique (indépendant, fonction publique)
  /// nécessaires pour un dossier locataire. L'ancienne entrée "Alternance"
  /// était ambiguë (elle recouvre à la fois l'apprentissage et la
  /// professionnalisation, déjà distingués ci-dessous) et a été retirée.
  static List<String> jobcontractList() {
    return [
      "CDI",
      "CDD",
      "CDD saisonnier",
      "CDD d'usage",
      "Intérim (contrat de mission)",
      "CDI intérimaire",
      "CDI de chantier ou d'opération",
      "Contrat d'apprentissage",
      "Contrat de professionnalisation",
      "Contrat aidé (CUI-CAE / CUI-CIE)",
      "Portage salarial",
      "Stage (convention de stage)",
      "Intermittence du spectacle",
      "Fonctionnaire / Contractuel de la fonction publique",
      "Indépendant / Profession libérale",
    ];
  }

  /// Types de revenus recevables pour un dossier locataire/garant, alignés
  /// sur les prestations et catégories officielles des organismes français
  /// concernés : CAF (prestations sociales et familiales), France Travail
  /// (ex-Pôle emploi, allocations chômage) et DGFiP (catégories de revenus).
  /// L'ancienne entrée "CAF" était ambiguë : elle désignait en fait une
  /// prestation précise (les allocations familiales), distincte de APL/AAH/
  /// RSA/prime d'activité qui sont aussi versées par la CAF mais déjà
  /// listées séparément - remplacée ci-dessous par son intitulé réel.
  static List<String> incomesType() {
    return [
      "Salaire",
      "Indemnités chômage (France Travail)",
      "Retraite",
      "Pension d'invalidité",
      "Pension alimentaire",
      "Indépendant / Profession libérale",
      "Revenus fonciers",
      "Revenus de capitaux mobiliers",
      "APL / ALS / ALF",
      "Allocations familiales",
      "Prime d'activité",
      "AAH",
      "RSA",
      "Bourse (CROUS ou autre)",
      "Aide parentale",
    ];
  }

  /// Sections A à U de la nomenclature NAF Rev. 2 (INSEE) - la
  /// classification officielle des grandes activités professionnelles en
  /// France, utilisée par l'URSSAF pour l'attribution du code APE. Volontairement
  /// limitée à ces 21 sections (et non aux ~732 sous-classes NAF détaillées)
  /// pour rester un choix exploitable dans un menu déroulant.
  static List<String> secteursActivite() {
    return [
      "Agriculture, sylviculture et pêche",
      "Industries extractives",
      "Industrie manufacturière",
      "Production et distribution d'électricité, de gaz, de vapeur et d'air conditionné",
      "Production et distribution d'eau, assainissement, gestion des déchets et dépollution",
      "Construction",
      "Commerce, réparation d'automobiles et de motocycles",
      "Transports et entreposage",
      "Hébergement et restauration",
      "Information et communication",
      "Activités financières et d'assurance",
      "Activités immobilières",
      "Activités spécialisées, scientifiques et techniques",
      "Activités de services administratifs et de soutien",
      "Administration publique",
      "Enseignement",
      "Santé humaine et action sociale",
      "Arts, spectacles et activités récréatives",
      "Autres activités de services",
      "Activités des ménages en tant qu'employeurs",
      "Activités extra-territoriales",
    ];
  }

  /// Catégories d'état civil / situation familiale utilisées par l'INSEE et
  /// la CAF dans les démarches administratives françaises.
  static List<String> situationsFamiliales() {
    return [
      "Célibataire",
      "Marié(e)",
      "Pacsé(e)",
      "Concubinage (union libre)",
      "Divorcé(e)",
      "Séparé(e)",
      "Veuf/Veuve",
    ];
  }

  /// Catégories de personnes à charge du formulaire de déclaration de
  /// revenus (2042, cases F/G/H de la DGFiP) : enfants mineurs, enfants
  /// majeurs rattachés, enfants en situation de handicap, ascendants et
  /// autres personnes titulaires d'une carte d'invalidité.
  static List<String> typesPersonneCharge() {
    return [
      "Enfant de moins de 18 ans",
      "Enfant de 18 à 25 ans (rattaché)",
      "Enfant en résidence alternée",
      "Enfant en situation de handicap",
      "Ascendant (parent) à charge",
      "Autre personne à charge (carte d'invalidité)",
    ];
  }

  /// "Relevés bancaires" a été retiré : l'article 22-2 de la loi du 6
  /// juillet 1989 (modifiée par la loi ALUR) interdit explicitement à un
  /// bailleur d'exiger un relevé de compte bancaire ou postal, que ce soit
  /// du locataire ou de sa caution.
  static List<String> docsTypeList() {
    return [
      "Fiche de salaire",
      "Attestation employeur",
      "Contrat de travail",
      "certificat de scolarité",
      "Justificatif de domicile",
      "Avis de pension",
      "Relevé de paiement retraite",
      "Notification d’attribution",
      "Justificatif CAF",
      "Déclaration d’impôts",
      "Relevés comptables",
      "Avis d’imposition foncier",
      "Contrat de location",
      "Avis de dividendes",
      "Notification APL",
      "Relevé prestations sociales",
      "Notification AAH",
      "Notification RSA",
      "Attestation bourse",
      "Notification CROUS",
      "Justificatif versements",
      "Recommandation",
      "Extrait Kbis ou URSSAF / INSEE",
      "Bilan comptable ",
      "Déclaration fiscale Société",
      "Acte de cautionnement",
    ];
  }

  /// Pas de nomenclature officielle pour le lien de parenté/relation entre
  /// un locataire et son garant - liste pragmatique couvrant les cas les
  /// plus courants d'un dossier de location.
  static List<String> liensGarantLocataire() {
    return [
      "Parent",
      "Grand-parent",
      "Frère/Sœur",
      "Oncle/Tante",
      "Conjoint(e) ou partenaire",
      "Ami(e)",
      "Employeur",
      "Autre",
    ];
  }
}
