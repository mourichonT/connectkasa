class IncomeEntry {
  final String label;
  final String amount;

  IncomeEntry({required this.label, required this.amount});

  factory IncomeEntry.fromMap(Map<String, dynamic> map) {
    return IncomeEntry(
      label: map['label'] ?? '',
      amount: map['amount'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'amount': amount,
    };
  }

  /// Méthode statique pour extraire la liste des revenus depuis une Map
}
