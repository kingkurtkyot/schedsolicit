import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../features/schedule/models/schedule_item.dart';
import '../../features/solicitation/models/solicitation_item.dart';

class SharePackager {
  SharePackager._();

  /// Packages schedules and solicitations into a self-contained, portable, zero-backend share token.
  static String createPackage({
    required String label,
    required List<ScheduleItem> schedules,
    required List<SolicitationItem> solicitations,
    bool hideAmounts = false,
    bool hideContacts = false,
    bool includeHistory = true,
  }) {
    // 1. Filter schedules
    final filteredSchedules = schedules.where((s) {
      if (!includeHistory && (s.status == 'Done' || s.status == 'Past' || s.status == 'Cancelled')) {
        return false;
      }
      return true;
    }).map((s) {
      final json = s.toJson();
      if (hideContacts) {
        // Sanitize any contact references if present in description
      }
      return json;
    }).toList();

    // 2. Filter & sanitize solicitations
    final filteredSolicitations = solicitations.where((s) {
      if (!includeHistory && (s.status == 'Given' || s.status == 'Declined' || s.status == 'Cancelled')) {
        return false;
      }
      return true;
    }).map((s) {
      final json = s.toJson();
      if (hideAmounts) {
        json['amount_requested'] = null;
        json['given_amount'] = null;
      }
      if (hideContacts) {
        json['phone'] = null;
        json['email'] = null;
        json['contact_person'] = null;
      }
      return json;
    }).toList();

    // 3. Assemble unified payload
    final payload = {
      'v': 1,
      'label': label,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'privacy': {
        'hide_amounts': hideAmounts,
        'hide_contacts': hideContacts,
      },
      'schedules': filteredSchedules,
      'solicitations': filteredSolicitations,
    };

    final jsonStr = jsonEncode(payload);

    // 4. Compress with gzip if supported on platform, otherwise raw UTF-8
    List<int> bytes;
    if (!kIsWeb) {
      try {
        bytes = gzip.encode(utf8.encode(jsonStr));
      } catch (_) {
        bytes = utf8.encode(jsonStr);
      }
    } else {
      bytes = utf8.encode(jsonStr);
    }

    // 5. Encode with URL-safe base64
    final base64String = base64UrlEncode(bytes);
    return 'SS1_$base64String';
  }

  /// Decodes and unpacks a share token back into schedules and solicitations.
  static Map<String, dynamic>? unpackPackage(String code) {
    try {
      String raw = code.trim();
      if (raw.startsWith('SS1_')) {
        raw = raw.substring(4);
      }
      final bytes = base64Url.decode(raw);
      String jsonStr;
      if (!kIsWeb) {
        try {
          final decompressed = gzip.decode(bytes);
          jsonStr = utf8.decode(decompressed);
        } catch (_) {
          jsonStr = utf8.decode(bytes);
        }
      } else {
        jsonStr = utf8.decode(bytes);
      }
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Unpack error: $e');
      return null;
    }
  }

  /// Generates the full 1-click share URL for the Viewer Portal.
  static String generateShareUrl(String packageCode, {String viewerBaseUrl = 'http://localhost:3000'}) {
    final cleanUrl = viewerBaseUrl.endsWith('/') ? viewerBaseUrl.substring(0, viewerBaseUrl.length - 1) : viewerBaseUrl;
    return '$cleanUrl/#d=$packageCode';
  }
}
