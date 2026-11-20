import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/features/shared/widgets/responsive_scaffold.dart';

void main() {
  group('Responsive Layout Tests', () {
    testWidgets('renders BottomNavigationBar on compact screen (375px)', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('renders NavigationRail on medium screen (768px)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('renders permanent drawer on desktop screen (1440px)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      expect(find.byType(Drawer), findsOneWidget);
    });
  });
}
