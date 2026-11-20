import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/share_packager.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../solicitation/providers/solicitation_provider.dart';
import '../models/share_link.dart';
import '../providers/share_provider.dart';

class CreateShareLinkScreen extends ConsumerStatefulWidget {
  const CreateShareLinkScreen({super.key});

  @override
  ConsumerState<CreateShareLinkScreen> createState() => _CreateShareLinkScreenState();
}

class _CreateShareLinkScreenState extends ConsumerState<CreateShareLinkScreen> {
  final _labelController = TextEditingController(text: 'Public Schedule & Solicitations');
  final _viewerUrlController = TextEditingController(text: 'http://localhost:3000');
  String _module = 'both';
  bool _includeHistory = false;
  bool _hideAmounts = false;
  bool _hideContacts = false;
  bool _allowExport = true;
  int _expiryDays = 30;

  @override
  void dispose() {
    _labelController.dispose();
    _viewerUrlController.dispose();
    super.dispose();
  }

  void _generateAndShowPackage() {
    final schedules = ref.read(scheduleListProvider).valueOrNull ?? [];
    final solicitations = ref.read(solicitationListProvider).valueOrNull ?? [];

    final label = _labelController.text.trim().isEmpty ? 'Shared Schedule' : _labelController.text.trim();

    // Generate zero-backend portable data package
    final packageCode = SharePackager.createPackage(
      label: label,
      schedules: _module == 'solicitation' ? [] : schedules,
      solicitations: _module == 'schedule' ? [] : solicitations,
      hideAmounts: _hideAmounts,
      hideContacts: _hideContacts,
      includeHistory: _includeHistory,
    );

    final viewerUrl = _viewerUrlController.text.trim();
    final fullShareUrl = SharePackager.generateShareUrl(packageCode, viewerBaseUrl: viewerUrl);

    // Save metadata locally
    final now = DateTime.now().toUtc();
    final link = ShareLink(
      id: const Uuid().v4(),
      token: packageCode.substring(0, 16),
      label: label,
      module: _module,
      scope: {'include_history': _includeHistory},
      privacyControls: {
        'hide_amounts': _hideAmounts,
        'hide_contacts': _hideContacts,
      },
      expiresAt: now.add(Duration(days: _expiryDays)),
      allowExport: _allowExport,
      createdAt: now,
      updatedAt: now,
    );
    ref.read(shareLinksProvider.notifier).addLink(link);

    // Show export dialog with 1-click link and encrypted code
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Share Package Ready'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zero-backend share package generated successfully. Viewers can open this link directly in Safari/Chrome without needing any server.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text('1-Click Viewer Link:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                fullShareUrl,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Link'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: fullShareUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied 1-click share link!'), behavior: SnackBarBehavior.floating),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.vpn_key, size: 16),
                    label: const Text('Copy Code'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: packageCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied share code!'), behavior: SnackBarBehavior.floating),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Share Now'),
            onPressed: () {
              Share.share(
                'View "$label" on SchedSolicit:\n$fullShareUrl\n\nOr paste this code in the portal:\n$packageCode',
                subject: label,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Zero-Backend Share Link')),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Banner
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withOpacity(0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Serverless Sharing: Exports an encrypted, standalone payload. Viewers can open the link in any browser or paste the code directly with zero servers required.',
                      style: TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Package Label / Event Name',
              hintText: 'e.g. Jia Jizelle Christening Details',
              prefixIcon: Icon(Icons.bookmark_outline),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _viewerUrlController,
            decoration: const InputDecoration(
              labelText: 'Viewer Portal Base URL',
              hintText: 'http://localhost:3000 or https://your-viewer.vercel.app',
              prefixIcon: Icon(Icons.language),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Module Scope', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'schedule', label: Text('Schedule')),
              ButtonSegment(value: 'solicitation', label: Text('Solicitations')),
              ButtonSegment(value: 'both', label: Text('Both')),
            ],
            selected: {_module},
            onSelectionChanged: (set) => setState(() => _module = set.first),
          ),
          const SizedBox(height: 24),

          const Text('Privacy Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SwitchListTile(
            title: const Text('Include Completed / History Items'),
            value: _includeHistory,
            onChanged: (val) => setState(() => _includeHistory = val),
          ),
          SwitchListTile(
            title: const Text('Hide Financial Amounts'),
            subtitle: const Text('Masks amount requested and given amounts'),
            value: _hideAmounts,
            onChanged: (val) => setState(() => _hideAmounts = val),
          ),
          SwitchListTile(
            title: const Text('Hide Personal Contacts'),
            subtitle: const Text('Masks phone numbers and emails'),
            value: _hideContacts,
            onChanged: (val) => setState(() => _hideContacts = val),
          ),
          SwitchListTile(
            title: const Text('Allow Viewer Export (PDF/CSV)'),
            value: _allowExport,
            onChanged: (val) => setState(() => _allowExport = val),
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Generate Share Package', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _generateAndShowPackage,
          ),
        ],
      ),
    );
  }
}
