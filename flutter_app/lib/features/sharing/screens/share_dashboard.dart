import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../providers/share_provider.dart';

class ShareDashboardScreen extends ConsumerWidget {
  const ShareDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(shareLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Links'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shareLinksProvider.notifier).refresh(),
          ),
        ],
      ),
      body: links.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No Active Share Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Create read-only portals for sponsors, volunteers, or partners with granular privacy controls.'),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Generate New Link'),
                      onPressed: () => context.push('/sharing/create'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: links.length,
              itemBuilder: (context, index) {
                final link = links[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: link.isRevoked ? Colors.red.shade100 : Colors.green.shade100,
                      child: Icon(
                        link.isRevoked ? Icons.link_off : Icons.link,
                        color: link.isRevoked ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(link.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Views: ${link.viewCount} · Expires: ${link.expiresAt != null ? DateFormat("MMM d, yyyy").format(link.expiresAt!) : "Never"}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'share') {
                          Share.share('http://localhost:3000/${link.token}', subject: link.label);
                        } else if (action == 'revoke') {
                          ref.read(shareLinksProvider.notifier).revokeLink(link.id);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'share', child: Text('Share Link')),
                        if (!link.isRevoked)
                          const PopupMenuItem(value: 'revoke', child: Text('Revoke Link', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sharing/create'),
        icon: const Icon(Icons.add_link),
        label: const Text('Create Link'),
      ),
    );
  }
}
