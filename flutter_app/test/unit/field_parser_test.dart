import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/features/scan/services/field_parser.dart';

void main() {
  group('FieldParser OCR Extraction Tests', () {
    test('extracts title, date, time and location from schedule poster', () {
      const text = '''
Annual General Gala
Date: Nov 25, 2026
Time: 10:00 AM - 1:00 PM
Location: Grand Ballroom Center
Join us for celebrating our partners.
''';

      final result = FieldParser.parseSchedule(text);
      expect(result.fields['title'], contains('Annual General Gala'));
      expect(result.fields['start_time'], isNotNull);
      expect(result.fields['location'], contains('Center'));
      expect(result.confidenceScores['title'], greaterThanOrEqualTo(0.8));
    });

    test('extracts organization, amount, email, and phone from solicitation letter', () {
      const text = '''
Youth Soccer Foundation
Contact: info@youthsoccer.org
Phone: (555) 234-5678
We are requesting \$5,000.00 for soccer gear.
''';

      final result = FieldParser.parseSolicitation(text);
      expect(result.fields['organization'], contains('Foundation'));
      expect(result.fields['email'], 'info@youthsoccer.org');
      expect(result.fields['phone'], '(555) 234-5678');
      expect(result.fields['amount_requested'], 5000.0);
    });
  });
}
