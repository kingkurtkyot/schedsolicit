import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/schedule/screens/schedule_tab.dart';
import '../../features/schedule/screens/schedule_detail.dart';
import '../../features/solicitation/screens/solicitation_tab.dart';
import '../../features/solicitation/screens/solicitation_detail.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/scan/screens/review_confirm_screen.dart';
import '../../features/export/screens/export_config_screen.dart';
import '../../features/export/screens/export_preview_screen.dart';
import '../../features/sharing/screens/share_dashboard.dart';
import '../../features/sharing/screens/create_share_link.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/shared/widgets/responsive_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/schedule',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final location = state.uri.toString();
          int currentIndex = 0;
          if (location.startsWith('/solicitation')) {
            currentIndex = 1;
          } else if (location.startsWith('/sharing')) {
            currentIndex = 2;
          } else if (location.startsWith('/settings')) {
            currentIndex = 3;
          }

          return ResponsiveScaffold(
            currentIndex: currentIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/schedule');
                  break;
                case 1:
                  context.go('/solicitation');
                  break;
                case 2:
                  context.go('/sharing');
                  break;
                case 3:
                  context.go('/settings');
                  break;
              }
            },
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const ScheduleTab(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ScheduleDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/solicitation',
            builder: (context, state) => const SolicitationTab(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => SolicitationDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sharing',
            builder: (context, state) => const ShareDashboardScreen(),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CreateShareLinkScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Scan routes
      GoRoute(
        path: '/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScanScreen(),
        routes: [
          GoRoute(
            path: 'review',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => ReviewConfirmScreen(
              data: state.extra as Map<String, dynamic>?,
            ),
          ),
        ],
      ),
      // Export routes
      GoRoute(
        path: '/export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ExportConfigScreen(
          filter: state.extra as dynamic,
        ),
        routes: [
          GoRoute(
            path: 'preview',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => ExportPreviewScreen(
              config: state.extra as Map<String, dynamic>?,
            ),
          ),
        ],
      ),
    ],
  );
}
