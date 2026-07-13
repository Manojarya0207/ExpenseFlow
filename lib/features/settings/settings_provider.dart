import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing app settings persisted via shared_preferences (§5.12).
@immutable
class AppSettings {
  const AppSettings({
    this.currencySymbol = '₹',
    this.themeMode = ThemeMode.system,
  });

  final String currencySymbol;
  final ThemeMode themeMode;

  AppSettings copyWith({String? currencySymbol, ThemeMode? themeMode}) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Loads/saves [AppSettings]. Emits a sensible default immediately, then
/// hydrates from disk asynchronously.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const String _kCurrency = 'settings.currency';
  static const String _kTheme = 'settings.themeMode';

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String currency = prefs.getString(_kCurrency) ?? '₹';
    final int themeIndex =
        prefs.getInt(_kTheme) ?? ThemeMode.system.index;
    state = AppSettings(
      currencySymbol: currency,
      themeMode: ThemeMode.values[themeIndex],
    );
  }

  Future<void> setCurrency(String symbol) async {
    state = state.copyWith(currencySymbol: symbol);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, symbol);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTheme, mode.index);
  }
}

final StateNotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (Ref ref) => SettingsNotifier(),
);
