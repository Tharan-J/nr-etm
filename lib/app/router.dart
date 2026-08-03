import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/screens/pairing_screen.dart';
import '../ui/screens/placeholder_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/ticketing_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/pairing',
      builder: (BuildContext context, GoRouterState state) {
        return const PairingScreen();
      },
    ),
    GoRoute(
      path: '/init',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Device Initialization',
          specReference: 'Spec 09 §8.2',
        );
      },
    ),
    GoRoute(
      path: '/battery-onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Battery Optimization Onboarding',
          specReference: 'Spec 09 §8.3',
        );
      },
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const TicketingScreen();
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const TicketingScreen();
      },
    ),
    GoRoute(
      path: '/trip-context',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Trip Context Detail',
          specReference: 'Spec 09 §8.5',
        );
      },
    ),
    GoRoute(
      path: '/ticketing/select-stops',
      builder: (BuildContext context, GoRouterState state) {
        return const TicketingScreen();
      },
    ),
    GoRoute(
      path: '/ticketing/fare-confirmation',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Fare Confirmation',
          specReference: 'Spec 09 §8.7',
        );
      },
    ),
    GoRoute(
      path: '/ticketing/ticket-confirmation',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Ticket Confirmation',
          specReference: 'Spec 09 §8.8',
        );
      },
    ),
    GoRoute(
      path: '/ticket-history',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Ticket History',
          specReference: 'Spec 09 §8.9',
        );
      },
    ),
    GoRoute(
      path: '/sync-detail',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Sync & Connectivity Status',
          specReference: 'Spec 09 §8.10',
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Settings & Diagnostics',
          specReference: 'Spec 09 §8.11',
        );
      },
    ),
    GoRoute(
      path: '/revoked',
      builder: (BuildContext context, GoRouterState state) {
        return const EtmPlaceholderScreen(
          title: 'Device Revoked / Unauthorized',
          specReference: 'Spec 09 §8.12',
        );
      },
    ),
  ],
);
