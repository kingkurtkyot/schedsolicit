import 'dart:math';

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
    final candidateTitle = _findBestScheduleTitle(lines);
    fields['title'] = candidateTitle;
    conf['title'] = 0.95;

    // 2. Date Extraction (Month, Day, Year, Ordinals, Multi-line support)
    final parsedDate = _extractDate(text, lines);
    if (parsedDate != null) {
      fields['event_date'] = parsedDate;
      conf['event_date'] = 0.98;
    }

    // 3. Time Extraction (Start and End Time)
    final times = _extractTimes(text);
    if (times.isNotEmpty) {
      fields['start_time'] = times[0];
      conf['start_time'] = 0.95;
      if (times.length > 1) {
        fields['end_time'] = times[1];
        conf['end_time'] = 0.92;
      }
    }

    // 4. Location Extraction
    final location = _extractLocation(lines);
    if (location != null) {
      fields['location'] = location;
      conf['location'] = 0.92;
    }

    // 5. Category Detection
    fields['category'] = _detectScheduleCategory(text);
    conf['category'] = 0.90;

    // 6. Priority Detection
    fields['priority'] = _detectPriority(text);
    conf['priority'] = 0.85;

    // 7. Description / Notes / Reception
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
    final candidateTitle = _findBestSolicitationTitle(lines);
    fields['title'] = candidateTitle;
    conf['title'] = 0.92;

    // 2. Amount Requested (PHP, $, ₱, USD, EUR, etc.)
    final amount = _extractAmount(text);
    if (amount != null && amount > 0) {
      fields['amount_requested'] = amount;
      conf['amount_requested'] = 0.98;
    }

    // 3. Organization Extraction
    final org = _extractOrganization(lines);
    if (org != null) {
      fields['organization'] = org;
      conf['organization'] = 0.92;
    }

    // 4. Contact Person Extraction
    final contactPerson = _extractContactPerson(lines);
    if (contactPerson != null) {
      fields['contact_person'] = contactPerson;
      conf['contact_person'] = 0.90;
    }

    // 5. Phone & Email
    final email = _extractEmail(text);
    if (email != null) {
      fields['email'] = email;
      conf['email'] = 0.98;
    }

    final phone = _extractPhone(text);
    if (phone != null) {
      fields['phone'] = phone;
      conf['phone'] = 0.94;
    }

    // 6. Deadline Extraction
    final deadline = _extractDate(text, lines);
    if (deadline != null) {
      fields['deadline'] = deadline;
      conf['deadline'] = 0.90;
    }

    // 7. Purpose / Description
    final purpose = _extractPurpose(text, lines);
    if (purpose != null) {
      fields['purpose'] = purpose;
      fields['notes'] = purpose;
      conf['purpose'] = 0.88;
    }

    // 8. Category & Priority
    fields['category'] = _detectSolicitationCategory(text);
    fields['priority'] = _detectPriority(text);

    return ParsedFieldResult(fields: fields, confidenceScores: conf);
  }

  // ================= Helper Parsers =================

  static String _findBestScheduleTitle(List<String> lines) {
    const eventKeywords = [
      'christening', 'baptism', 'birthday', 'wedding', 'anniversary',
      'dedication', 'reunion', 'seminar', 'conference', 'meeting',
      'assembly', 'concert', 'gala', 'tournament', 'league', 'mass',
      'celebration', 'party', 'shower', 'memorial', 'grad', 'graduation'
    ];

    const genericIgnore = [
      'you are invited to', 'invitation', 'cordially invited', 'save the date',
      'please join us', 'schedule', 'notice', 'announcement', 'memo',
      'memorandum', 'program of activities', 'join us as we celebrate',
      'god\'s blessing', 'in honor of', 'celebrate with us'
    ];

    // Check for "Name + Event" pattern (e.g., "Jia Jizelle Christening")
    for (int i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase().trim();
      for (final kw in eventKeywords) {
        if (lower.contains(kw)) {
          // If the line already has words besides the keyword (e.g. "Jia Jizelle Christening")
          if (lines[i].trim().split(RegExp(r'\s+')).length >= 2) {
            return _cleanTitle(lines[i]);
          }
          // If the previous line has a name (e.g. "JIA JIZELLE" followed by "Christening")
          if (i > 0 && !genericIgnore.any((g) => lines[i - 1].toLowerCase().contains(g))) {
            return '${_cleanTitle(lines[i - 1])} - ${_cleanTitle(lines[i])}';
          }
          // If the next line has a name
          if (i + 1 < lines.length && !genericIgnore.any((g) => lines[i + 1].toLowerCase().contains(g))) {
            return '${_cleanTitle(lines[i])}: ${_cleanTitle(lines[i + 1])}';
          }
          return _cleanTitle(lines[i]);
        }
      }
    }

    // Fallback: Find first prominent line that isn't a date or generic banner
    for (final line in lines) {
      final lower = line.toLowerCase().trim();
      if (lower.length < 3 || lower.length > 80) continue;
      if (genericIgnore.any((g) => lower == g || lower.startsWith(g))) continue;
      if (RegExp(r'^\d+$').hasMatch(lower)) continue;
      if (lower.startsWith('date:') || lower.startsWith('time:') || lower.startsWith('venue:')) continue;
      return _cleanTitle(line);
    }

    return lines.isNotEmpty ? _cleanTitle(lines.first) : 'Scanned Event';
  }

  static String _findBestSolicitationTitle(List<String> lines) {
    const genericIgnore = [
      'solicitation letter', 'solicitation', 'request letter', 'to whom it may concern',
      'dear sir/madam', 'greetings in peace', 'warm greetings', 're:', 'subject:'
    ];

    for (final line in lines) {
      final lower = line.toLowerCase().trim();
      if (lower.length < 4 || lower.length > 80) continue;
      if (genericIgnore.any((g) => lower == g || lower.startsWith(g))) continue;
      if (lower.startsWith('date:') || lower.startsWith('contact:')) continue;
      return _cleanTitle(line);
    }

    return lines.isNotEmpty ? _cleanTitle(lines.first) : 'Scanned Solicitation';
  }

  static String _cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'^(?:Title|Event|Subject|Re)[:\s]+', caseSensitive: false), '')
        .trim();
  }

  static DateTime? _extractDate(String text, [List<String>? lines]) {
    // 1. Month Name with Year on same line: e.g. "November 28, 2026", "Nov 28 2026", "28 Nov 2026", "November 28th, 2026"
    final monthNameWithYear = RegExp(
      r'\b(?:(0?[1-9]|[12]\d|3[01])(?:st|nd|rd|th)?\s+)?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+(?:(0?[1-9]|[12]\d|3[01])(?:st|nd|rd|th)?,?\s+)?(20\d\d)\b',
      caseSensitive: false,
    );
    final mMatch = monthNameWithYear.firstMatch(text);
    if (mMatch != null) {
      final monthStr = mMatch.group(2)!.toLowerCase();
      final month = _monthNumber(monthStr);
      final dayStr = mMatch.group(1) ?? mMatch.group(3) ?? '1';
      final day = int.tryParse(dayStr) ?? 1;
      final year = int.tryParse(mMatch.group(4) ?? '2026') ?? DateTime.now().year;
      return DateTime(year, month, day);
    }

    // 2. Month Name + Day without Year on same line: e.g. "November 28", "Nov 28th"
    // Search nearby lines or text for a 4-digit year 20xx
    final monthNameNoYear = RegExp(
      r'\b(?:(0?[1-9]|[12]\d|3[01])(?:st|nd|rd|th)?\s+)?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+(?:(0?[1-9]|[12]\d|3[01])(?:st|nd|rd|th)?)?\b',
      caseSensitive: false,
    );
    final noYearMatch = monthNameNoYear.firstMatch(text);
    if (noYearMatch != null) {
      final monthStr = noYearMatch.group(2)!.toLowerCase();
      final month = _monthNumber(monthStr);
      final dayStr = noYearMatch.group(1) ?? noYearMatch.group(3) ?? '1';
      final day = int.tryParse(dayStr);

      if (day != null && day >= 1 && day <= 31) {
        // Look for 20xx year anywhere in text
        final yearRegex = RegExp(r'\b(20\d\d)\b');
        final yMatch = yearRegex.firstMatch(text);
        final year = yMatch != null ? int.parse(yMatch.group(1)!) : DateTime.now().year;
        return DateTime(year, month, day);
      }
    }

    // 3. Match ISO: YYYY-MM-DD
    final isoRegex = RegExp(r'\b(20\d\d)[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b');
    final isoMatch = isoRegex.firstMatch(text);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      return DateTime(y, m, d);
    }

    // 4. Match MM/DD/YYYY or DD/MM/YYYY
    final slashRegex = RegExp(r'\b(0?[1-9]|1[0-2])/(0?[1-9]|[12]\d|3[01])/(20\d\d|\d{2})\b');
    final slashMatch = slashRegex.firstMatch(text);
    if (slashMatch != null) {
      var y = int.parse(slashMatch.group(3)!);
      if (y < 100) y += 2000;
      final m = int.parse(slashMatch.group(1)!);
      final d = int.parse(slashMatch.group(2)!);
      return DateTime(y, m, d);
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
    // e.g. 8:00 AM, 10:00am, 2:30 PM, 14:00, 8 AM, 8:00 A.M., 8:00 a.m.
    final timeRegex = RegExp(
      r'\b(\d{1,2}:\d{2}\s*(?:A\.M\.|P\.M\.|a\.m\.|p\.m\.|AM|PM|am|pm)?|\d{1,2}\s*(?:A\.M\.|P\.M\.|a\.m\.|p\.m\.|AM|PM|am|pm))\b',
      caseSensitive: false,
    );
    for (final match in timeRegex.allMatches(text)) {
      final t = match.group(1)!.trim().replaceAll('.', '');
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
      'shrine', 'parish', 'church', 'cathedral', 'chapel', 'basilica',
      'room', 'hall', 'gym', 'gymnasium', 'plaza', 'auditorium', 'center', 'centre',
      'building', 'floor', 'suite', 'street', 'st.', 'ave', 'avenue', 'blvd',
      'barangay hall', 'school grounds', 'park', 'subd', 'subdivision',
      'reception to follow', 'venue:', 'location:', 'where:'
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('venue:') || lower.startsWith('location:') || lower.startsWith('where:')) {
        return line.replaceAll(RegExp(r'^(?:venue|location|where)[:\s]+', caseSensitive: false), '').trim();
      }
      for (final kw in locKeywords) {
        if (lower.contains(kw) && line.length < 100) {
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
    final remaining = lines.where((l) => !title.contains(l) && l.length > 8).take(3).join('\n');
    return remaining.isNotEmpty ? remaining : null;
  }

  static String _detectScheduleCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('christening') || lower.contains('baptism') || lower.contains('church') || lower.contains('mass') || lower.contains('worship') || lower.contains('prayer')) return 'Church';
    if (lower.contains('birthday') || lower.contains('wedding') || lower.contains('anniversary') || lower.contains('reunion') || lower.contains('celebrat')) return 'Personal';
    if (lower.contains('meet') || lower.contains('conference') || lower.contains('assembly')) return 'Meeting';
    if (lower.contains('seminar') || lower.contains('training') || lower.contains('workshop')) return 'Seminar';
    if (lower.contains('basketball') || lower.contains('league') || lower.contains('tournament') || lower.contains('sports')) return 'Sports';
    if (lower.contains('fiesta') || lower.contains('festival')) return 'Festival';
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
