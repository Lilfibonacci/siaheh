/// Contract for persisting and reading the user's app theme preference.
abstract interface class ThemeLocalDataSource {
  String? get themeModeName;

  Future<void> setThemeModeName(String name);
}
