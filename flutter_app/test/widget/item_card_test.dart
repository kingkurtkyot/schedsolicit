import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/features/schedule/models/schedule_item.dart';
import 'package:schedsolicit/features/shared/widgets/item_card.dart';

void main() {
  group('ItemCard Widget Tests', () {
    testWidgets('renders card info with status chip and priority', (tester) async {
      final now = DateTime.now();
      final item = ScheduleItem(
        id: 'c-1',
        title: 'Community Fundraiser',
        eventDate: now,
        status: 'Active',
        priority: 'high',
        category: 'Donation',
        createdAt: now,
        updatedAt: now,
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemCard(
              item: item,
              dateLine: 'Made Today · On Event',
              onTap: () => tapped = true,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Community Fundraiser'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Donation'), findsOneWidget);

      await tester.tap(find.text('Community Fundraiser'));
      expect(tapped, true);
    });
  });
}
