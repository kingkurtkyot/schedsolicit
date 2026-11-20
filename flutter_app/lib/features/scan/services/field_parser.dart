import 'dart:math';
import 'package:intl/intl.dart';

class ParsedFieldResult {
  final Map<String, dynamic> fields;
  final Map<String, double> confidenceScores;
  final bool isMultiItem;
  final List<Map<String, dynamic>> subItems;

  const ParsedFieldResult({
    required this.fields,
    this.confidenceScores = const {},
    this.isMultiItem = false,
    this.subItems = const [],
  });
}

class FieldParser {
  FieldParser._();

  /// Parse schedule / event details from recognized text
  static ParsedFieldResult parseSchedule(String text) {
    final fields = <String, dynamic>{};
    final conf = <String, double>{};
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return const ParsedFieldResult(fields: {});

    // 1. Title Extraction
    // Skip headers like "SCHEDULE", "EVENT", "INVITATION", "NOTICE", or dates
    final candidateTitle = _findBestTitle(lines, defaultFallback: 'Scanned Event');
    fields['title'] = candidateTitle;
    conf['title'] = 0.88;

    // 2. Date Extraction
    final parsedDate = _extractDate(text);
    if (parsedDate != null) {
      fields['event_date'] = parsedDate;
      conf['event_date'] = 0.95;
    } else {
      fields['event_date'] = DateTime.now().add(const Duration(days: 1));
      conf['event_date'] = 0.50;
    }

    // 3. Time Extraction (Start and End Time)
    final times = _extractTimes(text);
    if (times.isNotEmpty) {
      fields['start_time'] = times[0];
      conf['start_time'] = 0.90;
      if (times.length > 1) {
        fields['end_time'] = times[1];
        conf['end_time'] = 0.88;
      }
    }

    // 4. Location Extraction
    final location = _extractLocation(lines);
    if (location != null) {
      fields['location'] = location;
      conf['location'] = 0.82;
    }

    // 5. Category Detection
    final category = _detectScheduleCategory(text);
    if (category != null) {
      fields['category'] = category;
      conf['category'] = 0.85;
    }

    // 6. Priority Detection
    fields['priority'] = _detectPriority(text);
    conf['priority'] = 0.80;

    // 7. Description / Notes
    final description = _extractDescription(lines, title: candidateTitle);
    if (description != null && description.isNotEmpty) {
      fields['description'] = description;
      fields['notes'] = description;
    }

    return ParsedFieldResult(fields: fields, confidenceScores: conf);
  }

  /// Parse solicitation letter / donation details from recognized text
  static ParsedFieldResult parseSolicitation(String text) {
    final fields = <String, dynamic>{};
    final conf = <String, double>{};
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return const ParsedFieldResult(fields: {});

    // 1. Title Extraction
    final candidateTitle = _findBestTitle(lines, defaultFallback: 'Scanned Solicitation');
    fields['title'] = candidateTitle;
    conf['title'] = 0.88;

    // 2. Amount Requested (PHP, $, ₱, USD, EUR, etc.)
    final amount = _extractAmount(text);
    if (amount != null && amount > 0) {
      fields['amount_requested'] = amount;
      conf['amount_requested'] = 0.95;
    }

    // 3. Organization Extraction
    final org = _extractOrganization(lines);
    if (org != null) {
      fields['organization'] = org;
      conf['organization'] = 0.88;
    }

    // 4. Contact Person Extraction
    final contactPerson = _extractContactPerson(lines);
    if (contactPerson != null) {
      fields['contact_person'] = contactPerson;
      conf['contact_person'] = 0.85;
    }

    // 5. Phone & Email
    final email = _extractEmail(text);
    if (email != null) {
      fields['email'] = email;
      conf['email'] = 0.96;
    }

    final phone = _extractPhone(text);
    if (phone != null) {
      fields['phone'] = phone;
      conf['phone'] = 0.92;
    }

    // 6. Deadline Extraction
    final deadline = _extractDate(text);
    if (deadline != null) {
      fields['deadline'] = deadline;
      conf['deadline'] = 0.85;
    }

    // 7. Purpose / Description
    final purpose = _extractPurpose(text, lines);
    if (purpose != null) {
      fields['purpose'] = purpose;
      fields['notes'] = purpose;
      conf['purpose'] = 0.80;
    }

    // 8. Category & Priority
    fields['category'] = _detectSolicitationCategory(text);
    fields['priority'] = _detectPriority(text);

    return ParsedFieldResult(fields: fields, confidenceScores: conf);
  }

  // ================= Helper Parsers =================

  static String _findBestTitle(List<String> lines, {required String defaultFallback}) {
    final ignoreKeywords = [
      'invitation', 'notice', 'announcement', 'memorandum', 'memo',
      'solicitation', 'solicitation letter', 'dear', 'to whom it may concern',
      'schedule of events', 'event schedule', 'program of activities',
      'page 1', 'date:', 'time:', 'venue:',
    ];

    for (final line in lines) {
      final lower = line.toLowerCase().trim();
      if (lower.length < 3 || lower.length > 90) continue;
      // Skip if line is just numbers or dates
      if (RegExp(r'^\d+$').hasMatch(lower)) continue;
      if (ignoreKeywords.contains(lower)) continue;
      // If line contains reasonable words, use it as title
      return line.trim();
    }

    return lines.isNotEmpty ? lines.first : defaultFallback;
  }

  static DateTime? _extractDate(String text) {
    // 1. Match ISO: YYYY-MM-DD
    final isoRegex = RegExp(r'\b(20\d\d)[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b');
    final isoMatch = isoRegex.firstMatch(text);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      return DateTime(y, m, d);
    }

    // 2. Match MM/DD/YYYY or DD/MM/YYYY
    final slashRegex = RegExp(r'\b(0?[1-9]|1[0-2])/(0?[1-9]|[12]\d|3[01])/(20\d\d|\d{2})\b');
    final slashMatch = slashRegex.firstMatch(text);
    if (slashMatch != null) {
      var y = int.parse(slashMatch.group(3)!);
      if (y < 100) y += 2000;
      final m = int.parse(slashMatch.group(1)!);
      final d = int.parse(slashMatch.group(2)!);
      return DateTime(y, m, d);
    }

    // 3. Match Month Name: e.g. "November 21, 2026", "Nov 21 2026", "21 Nov 2026"
    final monthNameRegex = RegExp(
      r'\b(?:(0?[1-9]|[12]\d|3[01])\s+)?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+(?:(0?[1-9]|[12]\d|3[01]),?\s+)?(20\d\d)\b',
      caseSensitive: false,
    );
    final monthMatch = monthNameRegex.firstMatch(text);
    if (monthMatch != null) {
      final monthStr = monthMatch.group(2)!.toLowerCase();
      final month = _monthNumber(monthStr);
      final dayStr = monthMatch.group(1) ?? monthMatch.group(3) ?? '1';
      final day = int.tryParse(dayStr) ?? 1;
      final year = int.tryParse(monthMatch.group(4) ?? '2026') ?? DateTime.now().year;
      return DateTime(year, month, day);
    }

    return null;
  }

  static int _monthNumber(String monthPrefix) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[monthPrefix.substring(0, min(3, monthPrefix.length))] ?? 1;
  }

  static List<String> _extractTimes(String text) {
    final times = <String>[];
    // e.g. 10:00 AM, 10:00am, 2:30 PM, 14:00, 8:00 AM - 5:00 PM
    final timeRegex = RegExp(r'\b(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?|\d{1,2}\s*(?:AM|PM|am|pm))\b');
    for (final match in timeRegex.allMatches(text)) {
      final t = match.group(1)!.trim();
      if (!times.contains(t)) {
        times.add(t);
      }
    }
    return times;
  }

  static double? _extractAmount(String text) {
    // Matches ₱5,000, Php 5,000, PHP 500.00, $5,000.00, P 5,000, Amount: 5000
    final patterns = [
      RegExp(r'(?:[\$₱£€]|PHP|Php|USD|EUR)\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:Amount|Total|Target|Goal|Donation|Fee|Price)[:\s]+(?:[\$₱£€]|PHP|Php)?\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'\bP\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)\b'),
    ];

    final candidates = <double>[];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final raw = match.group(1)!.replaceAll(',', '');
        final val = double.tryParse(raw);
        if (val != null && val > 0 && val < 100000000) {
          candidates.add(val);
        }
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.compareTo(a));
      return candidates.first;
    }
    return null;
  }

  static String? _extractOrganization(List<String> lines) {
    final orgKeywords = [
      'foundation', 'club', 'society', 'association', 'organization', 'org',
      'barangay', 'brgy', 'council', 'committee', 'parish', 'church',
      'school', 'university', 'college', 'pta', 'league', 'cooperative',
      'coop', 'group', 'company', 'corp', 'corporation', 'inc', 'llc',
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final kw in orgKeywords) {
        if (lower.contains(kw) && line.length < 80) {
          return line.trim();
        }
      }
    }
    return null;
  }

  static String? _extractContactPerson(List<String> lines) {
    final prefixRegex = RegExp(
      r'^(?:Contact|Coordinator|Chairman|Chairperson|President|From|Sincerely|Respectfully yours|Contact Person|Officer)[:\s]+(.+)$',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = prefixRegex.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        if (name.isNotEmpty && name.length < 60) return name;
      }
      if (line.toLowerCase().contains('sincerely') || line.toLowerCase().contains('respectfully')) {
        if (i + 1 < lines.length && lines[i + 1].trim().length < 60) {
          return lines[i + 1].trim();
        }
      }
    }
    return null;
  }

  static String? _extractPhone(String text) {
    final phonePatterns = [
      RegExp(r'\(\d{3}\)\s*\d{3}[-.\s]?\d{4}'), // (555) 234-5678
      RegExp(r'(?:\+63|0)[\s-]?9\d{2}[\s-]?\d{3}[\s-]?\d{4}'), // 0917-123-4567 or +63 917 123 4567
      RegExp(r'\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'), // standard US/Intl
      RegExp(r'\b\d{3}[-.\s]\d{3}[-.\s]\d{4}\b'), // 555-234-5678
    ];
    for (final p in phonePatterns) {
      final match = p.firstMatch(text);
      if (match != null) return match.group(0)?.trim();
    }
    return null;
  }

  static String? _extractEmail(String text) {
    final emailRegex = RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+');
    final match = emailRegex.firstMatch(text);
    return match?.group(0)?.trim();
  }

  static String? _extractLocation(List<String> lines) {
    final locKeywords = [
      'room', 'hall', 'gym', 'gymnasium', 'plaza', 'auditorium', 'center', 'centre',
      'building', 'floor', 'suite', 'street', 'st.', 'ave', 'avenue', 'blvd',
      'barangay hall', 'church', 'cathedral', 'chapel', 'school grounds', 'park',
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('venue:') || lower.startsWith('location:') || lower.startsWith('where:')) {
        return line.replaceAll(RegExp(r'^(?:venue|location|where)[:\s]+', caseSensitive: false), '').trim();
      }
      for (final kw in locKeywords) {
        if (lower.contains(kw) && line.length < 90) {
          return line.trim();
        }
      }
    }
    return null;
  }

  static String? _extractPurpose(String text, List<String> lines) {
    final purposeRegex = RegExp(
      r'(?:for the|in support of|financial assistance for|soliciting for|purpose of|aimed at)\s+([^\.\n]+)',
      caseSensitive: false,
    );
    final match = purposeRegex.firstMatch(text);
    if (match != null) {
      return match.group(0)!.trim();
    }
    if (lines.length > 2) {
      return lines.skip(1).take(2).join(' ');
    }
    return null;
  }

  static String? _extractDescription(List<String> lines, {required String title}) {
    final remaining = lines.where((l) => l != title && l.length > 5).take(3).join('\n');
    return remaining.isNotEmpty ? remaining : null;
  }

  static String _detectScheduleCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('meet') || lower.contains('conference') || lower.contains('assembly')) return 'Meeting';
    if (lower.contains('seminar') || lower.contains('training') || lower.contains('workshop')) return 'Seminar';
    if (lower.contains('basketball') || lower.contains('league') || lower.contains('tournament') || lower.contains('sports')) return 'Sports';
    if (lower.contains('church') || lower.contains('mass') || lower.contains('worship') || lower.contains('prayer')) return 'Church';
    if (lower.contains('fiesta') || lower.contains('festival') || lower.contains('celebration')) return 'Festival';
    if (lower.contains('clean') || lower.contains('community') || lower.contains('barangay')) return 'Community';
    return 'General';
  }

  static String _detectSolicitationCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('sponsor') || lower.contains('sponsorship')) return 'Sponsorship';
    if (lower.contains('donation') || lower.contains('donate')) return 'Donation';
    if (lower.contains('medical') || lower.contains('hospital') || lower.contains('treatment')) return 'Medical';
    if (lower.contains('fiesta') || lower.contains('festival')) return 'Fiesta';
    if (lower.contains('sports') || lower.contains('uniform') || lower.contains('league')) return 'Sports';
    if (lower.contains('school') || lower.contains('tuition') || lower.contains('education')) return 'Education';
    return 'General';
  }

  static String _detectPriority(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('urgent') || lower.contains('immediate') || lower.contains('emergency') || lower.contains('asap')) {
      return 'urgent';
    }
    if (lower.contains('important') || lower.contains('mandatory') || lower.contains('priority')) {
      return 'high';
    }
    return 'medium';
  }
}
