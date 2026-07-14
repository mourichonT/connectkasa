class DependentEntry {
  final String type;
  final String count;

  DependentEntry({required this.type, required this.count});

  factory DependentEntry.fromMap(Map<String, dynamic> map) {
    return DependentEntry(
      type: map['type'] ?? '',
      count: map['count'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'count': count,
    };
  }
}
