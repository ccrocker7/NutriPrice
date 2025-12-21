class WeightEntry {
  final double weight;
  final DateTime date;

  WeightEntry({required this.weight, required this.date});

  Map<String, dynamic> toMap() {
    return {'weight': weight, 'date': date.toIso8601String()};
  }

  factory WeightEntry.fromMap(Map<dynamic, dynamic> map) {
    return WeightEntry(
      weight: map['weight'] is double
          ? map['weight']
          : double.tryParse(map['weight'].toString()) ?? 0.0,
      date: DateTime.parse(map['date']),
    );
  }
}
