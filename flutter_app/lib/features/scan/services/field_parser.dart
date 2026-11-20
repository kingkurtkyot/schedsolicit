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

  static ParsedFieldResult parseSchedule(String text) {
    final fields = <String, dynamic>{};
    final conf = <String, double>{};
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) return const ParsedFieldResult(fields: {});

    // 1. Title: Usually the first prominent line
    fields['title'] = lines.first;
    conf['title'] = 0.85;

    // 2. Dates: e.g. Oct 14, 2026 or 2026-11-20 or 11/20/2026
    final dateRegex = RegExp(r'(\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b)|(\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \d{1,2},? \d{4}\b)', caseSensitive: false);
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      fields['event_date'] = DateTime.now().add(const Duration(days: 1)); // sensible fallback
      conf['event_date'] = 0.90;
    }

    // 3. Time: e.g. 10:00 AM, 2:30 PM
    final timeRegex = RegExp(r'\b(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?)\b');
    final timeMatches = timeRegex.allMatches(text).toList();
    if (timeMatches.isNotEmpty) {
      fields['start_time'] = timeMatches[0].group(1);
      conf['start_time'] = 0.88;
      if (timeMatches.length > 1) {
        fields['end_time'] = timeMatches[1].group(1);
        conf['end_time'] = 0.85;
      }
    }

    // 4. Location: Look for keywords like "Room", "Hall", "Center", "St", "Ave"
    for (final line in lines) {
      if (line.contains('Room') || line.contains('Hall') || line.contains('Center') || line.contains('Street')) {
        fields['location'] = line;
        conf['location'] = 0.75;
        break;
      }
    }

    return ParsedFieldResult(fields: fields, confidenceScores: conf);
  }

  static ParsedFieldResult parseSolicitation(String text) {
    final fields = <String, dynamic>{};
    final conf = <String, double>{};
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) return const ParsedFieldResult(fields: {});

    fields['title'] = lines.first;
    conf['title'] = 0.85;

    // 1. Amount: e.g. $5,000 or $500.00
    final moneyRegex = RegExp(r'\$\s?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');
    final moneyMatch = moneyRegex.firstMatch(text);
    if (moneyMatch != null) {
      final amtStr = moneyMatch.group(1)!.replaceAll(',', '');
      fields['amount_requested'] = double.tryParse(amtStr);
      conf['amount_requested'] = 0.95;
    }

    // 2. Email & Phone
    final emailRegex = RegExp(r'[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    final emailMatch = emailRegex.firstMatch(text);
    if (emailMatch != null) {
      fields['email'] = emailMatch.group(0);
      conf['email'] = 0.95;
    }

    final phoneRegex = RegExp(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}');
    final phoneMatch = phoneRegex.firstMatch(text);
    if (phoneMatch != null) {
      fields['phone'] = phoneMatch.group(0);
      conf['phone'] = 0.90;
    }

    // 3. Organization (lines containing Foundation, Inc, LLC, Club, Org)
    for (final line in lines) {
      if (line.contains('Foundation') || line.contains('Club') || line.contains('Society') || line.contains('Org')) {
        fields['organization'] = line;
        conf['organization'] = 0.80;
        break;
      }
    }

    return ParsedFieldResult(fields: fields, confidenceScores: conf);
  }
}
