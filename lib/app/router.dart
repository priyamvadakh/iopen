import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/content.dart';
import '../screens/explore_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inspect_screen.dart';
import '../screens/map_screen.dart';
import '../screens/place_view_screen.dart';
import '../screens/tab_screens.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRoute _tab(String path, Widget screen) =>
    GoRoute(path: path, builder: (context, state) => screen);

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => TabShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [_tab('/home', const HomeScreen())]),
        StatefulShellBranch(
          routes: [_tab('/sessions', const SessionsScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) =>
                  MapScreen(focusCityId: state.uri.queryParameters['city']),
            ),
          ],
        ),
        StatefulShellBranch(routes: [_tab('/wallet', const WalletScreen())]),
        StatefulShellBranch(routes: [_tab('/profile', const ProfileScreen())]),
      ],
    ),
    GoRoute(
      path: '/explore',
      builder: (context, state) => ExploreScreen(
        kind: InspectKind.fromName(state.uri.queryParameters['intent']),
      ),
    ),
    GoRoute(
      path: '/inspect/:kind',
      redirect: (context, state) =>
          InspectKind.fromName(state.pathParameters['kind']) == null
          ? '/home'
          : null,
      builder: (context, state) => InspectScreen(
        kind: InspectKind.fromName(state.pathParameters['kind'])!,
      ),
    ),
    GoRoute(
      path: '/city/:id',
      redirect: (context, state) =>
          cityById(state.pathParameters['id']!) == null ? '/home' : null,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        child: PlaceViewScreen(
          city: cityById(state.pathParameters['id']!)!,
          kind:
              InspectKind.fromName(state.uri.queryParameters['intent']) ??
              InspectKind.property,
          showIntro: true,
          areaId: state.uri.queryParameters['area'],
        ),
      ),
    ),
  ],
);
