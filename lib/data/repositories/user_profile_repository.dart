import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user_profile.dart';

class UserProfileRepository {
  static const String _userProfileKey = 'userProfile';

  /// Loads user profile from SharedPreferences
  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString(_userProfileKey);

    if (profileStr == null) {
      // Return default profile if none exists
      return UserProfile();
    }

    try {
      final json = jsonDecode(profileStr);
      return UserProfile.fromJson(json);
    } catch (e) {
      // If there's an error parsing, return default profile
      return UserProfile();
    }
  }

  /// Saves user profile to SharedPreferences
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profile.toJson()));
  }

  /// Updates user goals
  Future<void> updateGoals({
    required UserProfile currentProfile,
    required double calorieGoal,
    required double fatGoal,
    required double carbGoal,
    required double proteinGoal,
    required double budgetGoal,
  }) async {
    final updatedProfile = currentProfile.copyWith(
      calorieGoal: calorieGoal,
      fatGoal: fatGoal,
      carbGoal: carbGoal,
      proteinGoal: proteinGoal,
      budgetGoal: budgetGoal,
    );

    await saveProfile(updatedProfile);
  }
}
