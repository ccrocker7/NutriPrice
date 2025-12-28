class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    weight: (json['weight'] ?? 0.0).toDouble(),
  );
}
