import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/share_link.dart';
import '../providers/share_provider.dart';

class CreateShareLinkScreen extends ConsumerStatefulWidget {
  const CreateShareLinkScreen({super.key});

  @override
  ConsumerState<CreateShareLinkScreen> createState() => _CreateShareLinkScreenState();
}

class _CreateShareLinkScreenState extends ConsumerState<CreateShareLinkScreen> {
  final _labelController = TextEditingController(text: 'Public Viewer Link');
  String _module = 'both';
  bool _includeHistory = false;
  bool _hideAmounts = false;
  bool _hideContacts = false;
  bool _allowExport = true;
  int _expiryDays = 30;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Share Link')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Link Label / Description'),
          ),
          const SizedBox(height: 24),

          const Text('Module Scope', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

          const Text('Privacy & Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            subtitle: const Text('Masks phone numbers and email addresses'),
            value: _hideContacts,
            onChanged: (val) => setState(() => _hideContacts = val),
          ),
          SwitchListTile(
            title: const Text('Allow Viewer Export (PDF/CSV)'),
            value: _allowExport,
            onChanged: (val) => setState(() => _allowExport = val),
          ),
          const SizedBox(height: 24),

          const Text('Link Expiration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          DropdownButtonFormField<int>(
            value: _expiryDays,
            decoration: const InputDecoration(labelText: 'Expires in'),
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 Days')),
              DropdownMenuItem(value: 30, child: Text('30 Days')),
              DropdownMenuItem(value: 90, child: Text('90 Days')),
              DropdownMenuItem(value: 365, child: Text('1 Year')),
            ],
            onChanged: (val) => setState(() => _expiryDays = val ?? 30),
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Generate Share Link'),
            onPressed: () {
              final now = DateTime.now().toUtc();
              final link = ShareLink(
                id: const Uuid().v4(),
                token: const Uuid().v4().substring(0, 12),
                label: _labelController.text.trim().isEmpty ? 'Shared Link' : _labelController.text.trim(),
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
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
