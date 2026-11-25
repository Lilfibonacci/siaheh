import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:siaheh/data/datasources/theme_local_data_source.dart';

/// Hive-backed implementation of [ThemeLocalDataSource].
///
/// Uses the existing `sync_meta` box and `'theme_mode'` key to preserve
/// preferences across upgrades without migration loss.
class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  ThemeLocalDataSourceImpl(this._metaBox);

  static const String metaBoxName = 'sync_meta';
  static const String _themeModeKey = 'theme_mode';

  final Box<dynamic> _metaBox;

  static Future<ThemeLocalDataSourceImpl> open({Box<dynamic>? metaBox}) async {
    final box = metaBox ?? await Hive.openBox<dynamic>(metaBoxName);
    return ThemeLocalDataSourceImpl(box);
  }

  @override
  String? get themeModeName {
    final raw = _metaBox.get(_themeModeKey);
    return raw is String ? raw : null;
  }

  @override
  Future<void> setThemeModeName(String name) =>
      _metaBox.put(_themeModeKey, name);
}
