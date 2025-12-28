import 'package:shared_preferences/shared_preferences.dart';

/// Schema version constant for data migration support
const int kSchemaVersion = 3;

/// Key for storing the current schema version
const String _schemaVersionKey = 'current_schema_version';

/// Runs data migrations if needed
///
/// Checks the current schema version and applies migrations as needed.
/// - Version 1 (implicit): Original data structure without version key
/// - Version 2: Current structure with defensive decoding
class SchemaMigration {
  /// Runs all necessary migrations
  ///
  /// Returns true if migrations were successful
  static Future<bool> runMigrations() async {
    final prefs = await SharedPreferences.getInstance();

    // Get current version (defaults to 1 if not set)
    final currentVersion = prefs.getInt(_schemaVersionKey) ?? 1;

    if (currentVersion == kSchemaVersion) {
      // Already at the latest version
      return true;
    }

    // Run migrations based on current version
    if (currentVersion == 1) {
      await _migrateV1ToV2(prefs);
    }
    if (currentVersion <= 2) {
      await _migrateV2ToV3(prefs);
    }

    // Save the new schema version
    await prefs.setInt(_schemaVersionKey, kSchemaVersion);

    return true;
  }

  /// Migrates from v1 to v2
  static Future<void> _migrateV1ToV2(SharedPreferences prefs) async {
    // Defensive decoding handles missing fields
  }

  /// Migrates from v2 to v3
  ///
  /// Adds inventory tracking fields to existing pantry items
  static Future<void> _migrateV2ToV3(SharedPreferences prefs) async {
    final pantryStr = prefs.getString('pantry');
    if (pantryStr != null) {
      // The fromJson() with defensive defaults will handle this automatically
      // quantityRemaining defaults to 0.0
      // inventoryUnit defaults to servingUnit
      // No explicit migration code needed
    }
  }
}
