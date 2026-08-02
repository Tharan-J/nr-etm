import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/auth/domain/models/conductor_session.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  void _checkNavigation() {
    Future.microtask(() {
      final authState = ref.read(authNotifierProvider);
      authState.whenData((session) {
        if (!mounted) return;
        if (session.status == AuthStatus.authenticated) {
          context.go('/dashboard');
        } else {
          context.go('/pairing');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ConductorSession>>(authNotifierProvider, (
      previous,
      next,
    ) {
      next.whenData((session) {
        if (!mounted) return;
        if (session.status == AuthStatus.authenticated) {
          context.go('/dashboard');
        } else if (session.status == AuthStatus.unpaired) {
          context.go('/pairing');
        }
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textSecondary.withAlpha(51),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_rounded,
                    size: 72,
                    color: AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'NAMMAROUTE ETM',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Electronic Ticket Machine System',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing durable storage...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
