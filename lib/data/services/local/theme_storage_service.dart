import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Hive-backed local storage service for the user's app theme preference.
///
/// Uses the existing `sync_meta` box and `'theme_mode'` key to preserve
/// preferences across upgrades without migration loss.
class ThemeStorageService {
  ThemeStorageService(this._metaBox);

  static const String metaBoxName = 'sync_meta';
  static const String _themeModeKey = 'theme_mode';

  final Box<dynamic> _metaBox;

  static Future<ThemeStorageService> open({Box<dynamic>? metaBox}) async {
    final box = metaBox ?? await Hive.openBox<dynamic>(metaBoxName);
    return ThemeStorageService(box);
  }

  String? get themeModeName {
    final raw = _metaBox.get(_themeModeKey);
    return raw is String ? raw : null;
  }

  Future<void> setThemeModeName(String name) =>
      _metaBox.put(_themeModeKey, name);
}
