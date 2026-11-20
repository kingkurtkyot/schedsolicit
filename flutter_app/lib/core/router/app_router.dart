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

CustomTransitionPage<void> _buildSmoothTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/schedule',
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildSmoothTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
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
            pageBuilder: (context, state) => _buildSmoothTransition(
              context: context,
              state: state,
              child: const ScheduleTab(),
            ),
            routes: [
              GoRoute(
                path: 'detail/:id',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSmoothTransition(
                  context: context,
                  state: state,
                  child: ScheduleDetailScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/solicitation',
            pageBuilder: (context, state) => _buildSmoothTransition(
              context: context,
              state: state,
              child: const SolicitationTab(),
            ),
            routes: [
              GoRoute(
                path: 'detail/:id',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSmoothTransition(
                  context: context,
                  state: state,
                  child: SolicitationDetailScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sharing',
            pageBuilder: (context, state) => _buildSmoothTransition(
              context: context,
              state: state,
              child: const ShareDashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _buildSmoothTransition(
                  context: context,
                  state: state,
                  child: const CreateShareLinkScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildSmoothTransition(
              context: context,
              state: state,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      // Scan routes
      GoRoute(
        path: '/scan',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildSmoothTransition(
          context: context,
          state: state,
          child: const ScanScreen(),
        ),
        routes: [
          GoRoute(
            path: 'review',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => _buildSmoothTransition(
              context: context,
              state: state,
              child: ReviewConfirmScreen(
                data: state.extra as Map<String, dynamic>?,
              ),
            ),
          ),
        ],
      ),
      // Export routes
      GoRoute(
        path: '/export',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildSmoothTransition(
          context: context,
          state: state,
          child: ExportConfigScreen(
            filter: state.extra as dynamic,
          ),
        ),
        routes: [
          GoRoute(
            path: 'preview',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => _buildSmoothTransition(
              context: context,
              state: state,
              child: ExportPreviewScreen(
                config: state.extra as Map<String, dynamic>?,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
