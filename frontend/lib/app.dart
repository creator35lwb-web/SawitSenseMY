/// SawitSense MY — App Router & Theme Configuration
///
/// Navigation: Dashboard / Calculator / History (bottom nav bar)
/// Theme: Palm green + white, Material 3, mobile-first responsive

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/l10n_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/history_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/calculator',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalculatorScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
      ],
    ),
  ],
);

class SawitSenseApp extends ConsumerWidget {
  const SawitSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);

    return MaterialApp.router(
      title: tr('app_title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/calculator')) {
      currentIndex = 1;
    } else if (location.startsWith('/history')) {
      currentIndex = 2;
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/calculator');
            break;
          case 2:
            context.go('/history');
            break;
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: tr('nav_dashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.calculate_outlined),
          selectedIcon: const Icon(Icons.calculate),
          label: tr('nav_calculator'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.show_chart),
          selectedIcon: const Icon(Icons.show_chart),
          label: tr('nav_history'),
        ),
      ],
    );
  }
}
