import 'package:shared_preferences/shared_preferences.dart';

/// Schema version constant for data migration support
const int kSchemaVersion = 2;

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
      // Migration from v1 to v2
      // In v1, data already exists but doesn't have defensive decoding
      // The defensive decoding in fromJson() will handle missing fields
      // So we just need to update the version number
      await _migrateV1ToV2(prefs);
    }

    // Save the new schema version
    await prefs.setInt(_schemaVersionKey, kSchemaVersion);

    return true;
  }

  /// Migrates from v1 to v2
  ///
  /// In v1, all data exists but may have missing fields in some records
  /// The defensive decoding in the model classes will handle this
  static Future<void> _migrateV1ToV2(SharedPreferences prefs) async {
    // No actual data transformation needed
    // The fromJson() methods with defensive decoding will handle any missing fields
    // when the data is loaded

    // Future migrations could add code here to transform data structures
    // For example, if we add a new field with a non-default value:
    // - Load all items
    // - Add the new field with computed values
    // - Save back to SharedPreferences
  }
}
