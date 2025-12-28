class UserProfile {
  final String name;
  final double calorieGoal, fatGoal, carbGoal, proteinGoal, budgetGoal;

  UserProfile({
    this.name = "User",
    this.calorieGoal = 1600,
    this.fatGoal = 50,
    this.carbGoal = 150,
    this.proteinGoal = 100,
    this.budgetGoal = 15.00,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'calorieGoal': calorieGoal,
    'fatGoal': fatGoal,
    'carbGoal': carbGoal,
    'proteinGoal': proteinGoal,
    'budgetGoal': budgetGoal,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? "User",
    calorieGoal: (json['calorieGoal'] ?? 1600.0).toDouble(),
    fatGoal: (json['fatGoal'] ?? 50.0).toDouble(),
    carbGoal: (json['carbGoal'] ?? 150.0).toDouble(),
    proteinGoal: (json['proteinGoal'] ?? 100.0).toDouble(),
    budgetGoal: (json['budgetGoal'] ?? 15.00).toDouble(),
  );

  UserProfile copyWith({
    double? calorieGoal,
    double? fatGoal,
    double? carbGoal,
    double? proteinGoal,
    double? budgetGoal,
  }) {
    return UserProfile(
      name: name,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      budgetGoal: budgetGoal ?? this.budgetGoal,
    );
  }
}
