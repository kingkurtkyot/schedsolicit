import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/core/config/field_definitions.dart';
import 'package:schedsolicit/features/shared/widgets/dynamic_form.dart';

void main() {
  group('DynamicForm Widget Tests', () {
    testWidgets('renders schedule form fields and triggers onSave callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      Map<String, dynamic>? savedValues;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicForm(
              fields: FieldDefinitions.scheduleFields,
              onSave: (values) {
                savedValues = values;
              },
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Basic Info'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Enter title
      await tester.enterText(find.byType(TextFormField).first, 'Volunteer Rally');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedValues, isNotNull);
      expect(savedValues!['title'], 'Volunteer Rally');
    });

    testWidgets('respects field validation for required fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicForm(
              fields: FieldDefinitions.scheduleFields,
              onSave: (_) {},
            ),
          ),
        ),
      );

      // Tap save without filling required title
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget);
    });
  });
}
