import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/share_link.dart';

final shareLinksProvider = StateNotifierProvider<ShareLinksNotifier, List<ShareLink>>((ref) {
  return ShareLinksNotifier();
});

class ShareLinksNotifier extends StateNotifier<List<ShareLink>> {
  ShareLinksNotifier() : super([]) {
    _initSampleLinks();
  }

  void _initSampleLinks() {
    final now = DateTime.now().toUtc();
    state = [
      ShareLink(
        id: 'link-1',
        token: 'portal-volunteer-2026',
        label: 'Volunteer Coordination Portal',
        module: 'both',
        expiresAt: now.add(const Duration(days: 30)),
        viewCount: 14,
        allowExport: true,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void addLink(ShareLink link) {
    state = [link, ...state];
  }

  void revokeLink(String id) {
    state = state.map((l) {
      if (l.id == id) {
        return ShareLink(
          id: l.id,
          token: l.token,
          label: l.label,
          module: l.module,
          scope: l.scope,
          privacyControls: l.privacyControls,
          expiresAt: l.expiresAt,
          viewLimit: l.viewLimit,
          viewCount: l.viewCount,
          allowExport: l.allowExport,
          isRevoked: true,
          createdAt: l.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
      }
      return l;
    }).toList();
  }

  void refresh() {
    // Refresh links from server / local storage
  }
}
