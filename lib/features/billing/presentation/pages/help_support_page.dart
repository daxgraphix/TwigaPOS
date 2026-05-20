import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  Future<void> _launchMail(String address) async {
    final uri = Uri(scheme: 'mailto', path: address);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
          onPressed: () { if (context.canPop()) { context.pop(); } else { context.go('/'); } },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const ExpansionTile(
            title: Text('How do I add a new product?'),
            children: [Padding(padding: EdgeInsets.all(16), child: Text('Go to Products > Add Product and fill in the details.'))],
          ),
          const ExpansionTile(
            title: Text('How do I process a sale?'),
            children: [Padding(padding: EdgeInsets.all(16), child: Text('Use the New Sale screen to add items manually or search, then checkout.'))],
          ),
          const ExpansionTile(
            title: Text('How do I backup my data?'),
            children: [Padding(padding: EdgeInsets.all(16), child: Text('Go to Settings > Data Management > Backup Data.'))],
          ),
          const ExpansionTile(
            title: Text('How do I switch to dark mode?'),
            children: [Padding(padding: EdgeInsets.all(16), child: Text('Go to Settings > Theme and select Dark.'))],
          ),
          const ExpansionTile(
            title: Text('How do I customize my shop profile?'),
            children: [Padding(padding: EdgeInsets.all(16), child: Text('Go to Settings > Shop Profile to edit name, address, etc.'))],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: const Text('Contact Support'),
            subtitle: const Text('support@twigapos.com'),
            trailing: const Icon(Icons.launch),
            onTap: () => _launchMail('support@twigapos.com'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone'),
            subtitle: const Text('+255 700 000 000'),
            trailing: const Icon(Icons.launch),
            onTap: () => _launchPhone('+255700000000'),
          ),
          const Divider(),
            ListTile(
              leading: const Icon(Icons.video_call),
              title: const Text('Video Tutorial'),
              subtitle: const Text('Watch how to use TwigaPOS'),
              trailing: const Icon(Icons.launch),
              onTap: () => context.push('/planner'), // For now, link to planner as video tutorial placeholder
            ),
          const Divider(),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Documentation'),
              subtitle: const Text('Read the user guide'),
              trailing: const Icon(Icons.launch),
              onTap: () => context.push('/about'), // For now, link to about as documentation placeholder
            ),
        ],
      ),
    );
  }
}

