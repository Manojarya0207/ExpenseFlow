import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/section_header.dart';
import 'settings_provider.dart';

/// Settings tab: currency + theme (persisted), with placeholders for features
/// arriving in later passes (§5.12).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          const SectionHeader(title: 'Currency'),
          Card(
            child: RadioGroup<String>(
              groupValue: settings.currencySymbol,
              onChanged: (String? v) {
                if (v != null) notifier.setCurrency(v);
              },
              child: Column(
                children: <Widget>[
                  _currencyTile('₹', 'Indian Rupee'),
                  const Divider(height: 1),
                  _currencyTile(r'$', 'US Dollar'),
                  const Divider(height: 1),
                  _currencyTile('€', 'Euro'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Appearance'),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (ThemeMode? v) {
                if (v != null) notifier.setThemeMode(v);
              },
              child: Column(
                children: <Widget>[
                  _themeTile(ThemeMode.system, 'System default',
                      Icons.brightness_auto),
                  const Divider(height: 1),
                  _themeTile(ThemeMode.light, 'Light', Icons.light_mode),
                  const Divider(height: 1),
                  _themeTile(ThemeMode.dark, 'Dark', Icons.dark_mode),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'More'),
          Card(
            child: Column(
              children: const <Widget>[
                _ComingSoonTile(
                  icon: Icons.account_balance_wallet,
                  title: 'Budget Management',
                ),
                Divider(height: 1),
                _ComingSoonTile(
                  icon: Icons.notifications_active,
                  title: 'Daily Reminder',
                ),
                Divider(height: 1),
                _ComingSoonTile(
                  icon: Icons.lock,
                  title: 'PIN / Fingerprint Lock',
                ),
                Divider(height: 1),
                _ComingSoonTile(
                  icon: Icons.cloud_upload,
                  title: 'Google Drive Backup',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'ExpenseFlow • v1.0.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyTile(String symbol, String name) {
    return RadioListTile<String>(
      value: symbol,
      title: Text('$name  ($symbol)'),
    );
  }

  Widget _themeTile(ThemeMode mode, String label, IconData icon) {
    return RadioListTile<ThemeMode>(
      value: mode,
      secondary: Icon(icon),
      title: Text(label),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Chip(
        label: Text('Soon'),
        visualDensity: VisualDensity.compact,
      ),
      enabled: false,
    );
  }
}
