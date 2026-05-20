import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/supabase/supabase_config.dart';
import 'package:twigapos/features/shop/data/models/shop_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
                onPressed: () { if (context.canPop()) { context.pop(); } else { context.go('/'); } },
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Appearance Section
            _buildSectionHeader('Appearance'),
            _buildListGroup(
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppTheme.themeModeNotifier,
                  builder: (context, themeMode, child) {
                    return _buildListItem(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle:
                          AppLocalizations.of(context)!.darkMode == 'Dark Mode'
                              ? (themeMode == ThemeMode.dark ? 'On' : 'Off')
                              : (themeMode == ThemeMode.dark
                                  ? 'Imewashwa'
                                  : 'Imazimio'),
                      trailingWidget: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          AppTheme.themeModeNotifier.value =
                              value ? ThemeMode.dark : ThemeMode.light;
                          Hive.box('settings').put('darkMode', value);
                          Hive.box('settings').put('themeMode',
                              value ? 'dark' : 'light');
                        },
                      ),
                      onTap: () {
                        final isDark = themeMode == ThemeMode.dark;
                        final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                        AppTheme.themeModeNotifier.value = newMode;
                        Hive.box('settings').put('darkMode', !isDark);
                        Hive.box('settings').put('themeMode', isDark ? 'light' : 'dark');
                      },
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: 'Choose Light or Dark mode',
                  onTap: () => _showThemeDialog(context),
                ),
                _buildDivider(),
                ValueListenableBuilder<Locale>(
                  valueListenable: AppTheme.localeNotifier,
                  builder: (context, locale, child) {
                    return _buildListItem(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: locale.languageCode == 'sw' ? 'Kiswahili' : 'English',
                      onTap: () => _showLanguageDialog(context),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Profile Section
            _buildSectionHeader('Profile'),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.person,
                  title: 'My Profile',
                  subtitle: 'Update your name, email and avatar',
                  onTap: _editUserProfile,
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.store,
                  title: 'Shop Profile',
                  subtitle: 'Customize shop name, logo & details',
                  onTap: _editShopProfile,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Section
            _buildSectionHeader('Data Management'),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.backup,
                  title: 'Backup Data',
                  subtitle: 'Export all data to backup file',
                  onTap: _backupData,
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.restore,
                  title: 'Restore Data',
                  subtitle: 'Restore from a backup file',
                  onTap: _restoreData,
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.share,
                  title: 'Export & Share',
                  subtitle: 'Export data and share',
                  onTap: _exportAndShare,
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.cleaning_services,
                  title: 'Clear Cache',
                  subtitle: 'Clear app cache and temp data',
                  onTap: _clearCache,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sync Section
            _buildSectionHeader('Cloud Sync'),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.cloud_upload,
                  title: 'Sync to Cloud',
                  subtitle: 'Upload local data to Supabase',
                  onTap: _syncToCloud,
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.cloud_download,
                  title: 'Sync from Cloud',
                  subtitle: 'Download data from Supabase',
                  onTap: _syncFromCloud,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader('About'),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.info,
                  title: 'About TwigaPOS',
                  subtitle: 'Version 1.0.0',
                  onTap: () => context.push('/about'),
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.description,
                  title: 'Terms and Conditions',
                  subtitle: 'Read our terms of service',
                  onTap: () => context.push('/terms'),
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () => context.push('/privacy'),
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () => GoRouter.of(context).push('/help-support'),
                ),
              ],
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildListGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitleWidget ?? (subtitle != null ? Text(subtitle) : null),
      trailing: trailingWidget,
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 16, endIndent: 16);

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                AppTheme.localeNotifier.value = const Locale('en');
                Hive.box('settings').put('languageCode', 'en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Swahili (Kiswahili)'),
              onTap: () {
                AppTheme.localeNotifier.value = const Locale('sw');
                Hive.box('settings').put('languageCode', 'sw');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () {
                AppTheme.themeModeNotifier.value = ThemeMode.light;
                Hive.box('settings').put('darkMode', false);
                Hive.box('settings').put('themeMode', 'light');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () {
                AppTheme.themeModeNotifier.value = ThemeMode.dark;
                Hive.box('settings').put('darkMode', true);
                Hive.box('settings').put('themeMode', 'dark');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFile = File('${directory.path}/twigapos_backup_$timestamp.json');

      final products = HiveDatabase.productBox.values.map((p) => p.toJson()).toList();
      final shop = HiveDatabase.shopBox.get('shop_details');

      final settingsMap = <String, dynamic>{};
      for (var key in HiveDatabase.settingsBox.keys) {
        settingsMap[key] = HiveDatabase.settingsBox.get(key);
      }

      final backup = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'products': products,
        'shop': shop is ShopModel ? shop.toJson() : shop,
        'settings': settingsMap,
      };

      await backupFile.writeAsString(jsonEncode(backup));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to ${backupFile.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  Future<void> _restoreData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final tempDir = Directory(dir.path);
      final entities = await tempDir.list().toList();
      final backupEntry = entities
          .whereType<File>()
          .where((f) => f.path.contains('twigapos_backup_') && f.path.endsWith('.json'))
          .cast<File>()
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (backupEntry.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No backup file found. Please create a backup first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final backupFile = backupEntry.first;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Backup?'),
          content: Text(
            'This will replace ALL current data with the backup data.\n\n'
            'Backup file:\n${backupFile.path.split(Platform.pathSeparator).last}\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Restore', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final jsonString = await backupFile.readAsString();
      await HiveDatabase.importAllData(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _syncToCloud() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syncing to cloud...')),
      );
      final jsonData = await HiveDatabase.exportAllData();
      final payload = jsonEncode(jsonDecode(jsonData));
      await SupabaseConfig.client
          .from('backups')
          .upsert({'id': 'latest', 'data': payload, 'synced_at': DateTime.now().toIso8601String()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data synced to cloud successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync to cloud failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading from cloud...')),
      );
      final result = await SupabaseConfig.client
          .from('backups')
          .select('data')
          .eq('id', 'latest')
          .maybeSingle();
      if (result == null || result['data'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No cloud backup found. Sync to cloud first.'),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore from Cloud?'),
          content: const Text(
            'This will replace all current local data with the cloud backup. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Restore', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await HiveDatabase.importAllData(result['data'] as String);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored from cloud')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync from cloud failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportAndShare() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportFile = File('${directory.path}/twigapos_export_$timestamp.json');

      final products = HiveDatabase.productBox.values.map((p) => p.toJson()).toList();
      final shop = HiveDatabase.shopBox.get('shop_details');
      final settingsMap = <String, dynamic>{};
      for (var key in HiveDatabase.settingsBox.keys) {
        settingsMap[key] = HiveDatabase.settingsBox.get(key);
      }
      final transactions = HiveDatabase.transactionBox.values
          .map((t) => {
                'id': t.id,
                'description': t.description,
                'amount': t.amount,
                'date': t.date.toIso8601String(),
                'type': t.type.name,
              })
          .toList();

      final exportData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'products': products,
        'shop': shop is ShopModel ? shop.toJson() : shop,
        'settings': settingsMap,
        'transactions': transactions,
      };

      await exportFile.writeAsString(jsonEncode(exportData));

      if (mounted) {
        await Share.shareXFiles(
          [XFile(exportFile.path)],
          text: 'TwigaPOS Data Export',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported and shared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: $e')),
      );
    }
  }

  void _editShopProfile() {
    final shopBox = HiveDatabase.shopBox;
    final currentShop = shopBox.get('shop_details');
    final nameController = TextEditingController(text: currentShop?.name ?? '');
    final address1Controller = TextEditingController(text: currentShop?.addressLine1 ?? '');
    final address2Controller = TextEditingController(text: currentShop?.addressLine2 ?? '');
    final phoneController = TextEditingController(text: currentShop?.phoneNumber ?? '');
    final upiController = TextEditingController(text: currentShop?.upiId ?? '');
    final footerController = TextEditingController(text: currentShop?.footerText ?? '');
    final logoController = TextEditingController(text: currentShop?.logoText ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Shop Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Shop Name *'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: address1Controller,
                  decoration: const InputDecoration(labelText: 'Address Line 1 *'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: address2Controller,
                  decoration: const InputDecoration(labelText: 'Address Line 2'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixText: '+',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI / Payment ID',
                    hintText: 'e.g. upi://pay@bank',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: logoController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Logo Text',
                    hintText: 'Text shown on receipts',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: footerController,
                  decoration: const InputDecoration(
                    labelText: 'Receipt Footer',
                    hintText: 'Thank you message',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shop Name is required'), backgroundColor: Colors.red),
                  );
                  return;
                }
                if (address1Controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address Line 1 is required'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final updatedShop = ShopModel(
                  id: currentShop?.id ?? 'shop_1',
                  name: nameController.text.trim(),
                  addressLine1: address1Controller.text.trim(),
                  addressLine2: address2Controller.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  footerText: footerController.text.trim(),
                  upiId: upiController.text.trim(),
                  logoText: logoController.text.trim(),
                );
                shopBox.put('shop_details', updatedShop);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shop profile updated successfully')),
                  );
                }
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editUserProfile() async {
    final settingsBox = Hive.box('settings');
    final nameController = TextEditingController(
        text: settingsBox.get('userName', defaultValue: ''));
    final emailController = TextEditingController(
        text: settingsBox.get('userEmail', defaultValue: ''));
    final phoneController = TextEditingController(
        text: settingsBox.get('userPhone', defaultValue: ''));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              settingsBox.put('userName', nameController.text.trim());
              settingsBox.put('userEmail', emailController.text.trim());
              settingsBox.put('userPhone', phoneController.text.trim());

              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Profile updated successfully')),
                );
              }
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

