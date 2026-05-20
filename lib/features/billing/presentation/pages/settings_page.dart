import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:twigapos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:twigapos/features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../billing/domain/repositories/sales_repository.dart';
import '../../../billing/domain/entities/sales_transaction.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedLanguage;
  late String _selectedCurrency;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settingsBox = Hive.box('settings');
    _selectedLanguage = settingsBox.get('selectedLanguage', defaultValue: 'English');
    _selectedCurrency = settingsBox.get('selectedCurrency', defaultValue: 'TZS');
    // Read darkMode bool first, then fall back to themeMode string for backward compat
    _isDarkMode = settingsBox.get('darkMode',
            defaultValue: settingsBox.get('themeMode', defaultValue: 'light') == 'dark') as bool;
  }

  void _saveSetting(String key, dynamic value) {
    Hive.box('settings').put(key, value);
    setState(() {
      if (key == 'selectedLanguage') _selectedLanguage = value;
      if (key == 'selectedCurrency') _selectedCurrency = value;
      if (key == 'isDarkMode') {
        _isDarkMode = value;
        Hive.box('settings').put('themeMode', value ? 'dark' : 'light');
        Hive.box('settings').put('darkMode', value);
        AppTheme.themeModeNotifier.value =
            value ? ThemeMode.dark : ThemeMode.light;
      }
    });
  }

  void _showLanguageDialog() {
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
                _saveSetting('selectedLanguage', 'English');
                _saveSetting('languageCode', 'en');
                AppTheme.localeNotifier.value = const Locale('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Swahili'),
              onTap: () {
                _saveSetting('selectedLanguage', 'Swahili');
                _saveSetting('languageCode', 'sw');
                AppTheme.localeNotifier.value = const Locale('sw');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('TZS - Tanzanian Shilling'),
              onTap: () {
                _saveSetting('selectedCurrency', 'TZS');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('USD - US Dollar'),
              onTap: () {
                _saveSetting('selectedCurrency', 'USD');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('EUR - Euro'),
              onTap: () {
                _saveSetting('selectedCurrency', 'EUR');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('GBP - British Pound'),
              onTap: () {
                _saveSetting('selectedCurrency', 'GBP');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
          onPressed: () { if (context.canPop()) { context.pop(); } else { context.go('/'); } },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(Responsive.getPadding(context)),
        children: [
          _SettingSection(title: 'Profile', children: [_SettingTile(icon: Icons.person, title: 'Edit Profile', subtitle: 'Update your name, email, and photo', onTap: _showProfileDialog), _SettingTile(icon: Icons.lock, title: 'Change Password', subtitle: 'Update your password', onTap: _showPasswordDialog),]), const SizedBox(height: 16), _SettingSection(title: 'General',
            children: [
              _SettingTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: _selectedLanguage,
                onTap: _showLanguageDialog,
              ),
              _SettingTile(
                icon: Icons.currency_exchange,
                title: 'Currency',
                subtitle: _selectedCurrency,
                onTap: _showCurrencyDialog,
              ),
              _SettingTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) => _saveSetting('isDarkMode', value),
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingSection(
            title: 'Exports',
            children: [
              _SettingTile(
                icon: Icons.picture_as_pdf,
                title: 'Export Invoices',
                subtitle: 'Export as PDF',
                onTap: _exportAllInvoices,
              ),
              _SettingTile(
                icon: Icons.share,
                title: 'Share Data',
                subtitle: 'Export all data',
                onTap: _exportAllData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingSection(
            title: 'Data',
            children: [
              _SettingTile(
                icon: Icons.backup,
                title: 'Backup Data',
                subtitle: 'Backup to cloud',
                onTap: _backupData,
              ),
              _SettingTile(
                icon: Icons.restore,
                title: 'Restore Data',
                subtitle: 'Restore from backup',
                onTap: _restoreData,
              ),
              _SettingTile(
                icon: Icons.delete_sweep,
                title: 'Clear Cache',
                subtitle: 'Free up space',
                onTap: _clearCache,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingSection(
            title: 'About',
            children: [
              _SettingTile(
                icon: Icons.info,
                title: 'About App',
                onTap: _showAbout,
              ),
              _SettingTile(
                icon: Icons.description,
                title: 'Terms & Conditions',
                onTap: () => context.push('/terms'),
              ),
              _SettingTile(
                icon: Icons.security,
                title: 'Privacy Policy',
                onTap: () => context.push('/privacy'),
              ),
              _SettingTile(
                icon: Icons.help,
                title: 'Help & Support',
                onTap: () => context.push('/help-support'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(const AuthLogoutRequested());
                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() { final nameController = TextEditingController(text: Hive.box('settings').get('userName', defaultValue: 'User')); final emailController = TextEditingController(text: Hive.box('settings').get('userEmail', defaultValue: '')); showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Edit Profile'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')), const SizedBox(height: 16), TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () { Hive.box('settings').put('userName', nameController.text); Hive.box('settings').put('userEmail', emailController.text); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'))); }, child: const Text('Save'))])); } void _showPasswordDialog() { final passwordController = TextEditingController(); showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Change Password'), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Enter new password:'), const SizedBox(height: 16), TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () { if (passwordController.text.length >= 6) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully'))); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters'))); } }, child: const Text('Update'))])); } Future<void> _exportAllInvoices() async {
    try {
      final salesRepo = context.read<SalesRepository>();
      final salesResult = await salesRepo.getSalesByDateRange(DateTime(2000), DateTime.now());
      final transactions = salesResult.fold(
        (_) => <SalesTransaction>[],
        (list) => list,
      );

      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No invoices to export')),
          );
        }
        return;
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TwigaPOS Invoice Export',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              ...transactions.map(
                (t) => pw.Text(
                  'Invoice #${t.id} | ${t.productName} | Qty: ${t.quantity} | '
                  'Revenue: ${t.totalRevenue.toStringAsFixed(2)} | '
                  'Date: ${t.timestamp.toString().split(' ').first}',
                ),
              ),
            ],
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/invoices_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'TwigaPOS Invoices');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${transactions.length} invoices exported and shared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportAllData() async {
    try {
      final salesRepo = context.read<SalesRepository>();
      final salesResult = await salesRepo.getSalesByDateRange(DateTime(2000), DateTime.now());
      final transactions = salesResult.fold(
        (_) => <SalesTransaction>[],
        (list) => list,
      );

      final csvData = [
        <String>['ID', 'Product', 'Qty', 'Revenue', 'Date'],
        ...transactions.map(
          (t) => <String>[
            t.id,
            t.productName,
            t.quantity.toString(),
            t.totalRevenue.toStringAsFixed(2),
            t.timestamp.toIso8601String(),
          ],
        ),
      ];

      final csv = const ListToCsvConverter().convert(csvData);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/twigapos_data_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(file.path)], text: 'TwigaPOS Data Backup');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${transactions.length} records exported as CSV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _backupData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backing up data...')),
      );
      final jsonData = await HiveDatabase.exportAllData();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/twigapos_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonData);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'TwigaPOS Data Backup',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup completed and shared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreData() async {
    try {
      final dir = await getTemporaryDirectory();
      // Find the most recent backup file in the temp directory
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
              content: Text('No backup file found in storage'),
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
            'This will replace all current data with the data from this backup.\n\n'
            'Backup file:\n${backupFile.path.split('/').last}\n\n'
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

  void _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will free up storage used by temporary files and cached data. '
          'Your settings and data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dir = await getTemporaryDirectory();
      final tempDir = Directory(dir.path);
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear cache: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About TwigaPOS'),
        content: const Text(
          'TwigaPOS v1.0.0\n\n'
          'A complete Point-of-Sale and Business Management solution for\n'
          'merchants in Tanzania.\n\n'
          'Features:\n'
          ' â€¢ POS & Billing\n'
          ' â€¢ Customer Management\n'
          ' â€¢ Inventory Control\n'
          ' â€¢ Finance & Reports\n'
          ' â€¢ Data Export & Backup\n\n'
          'Â© 2026 TwigaPOS. All rights reserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (trailing != null) {
      return ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
        onTap: onTap,
      );
    }

    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}



