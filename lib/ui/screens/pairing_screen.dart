import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/auth/domain/models/pairing_request.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busIdController = TextEditingController(text: 'BUS_101');
  final _pinController = TextEditingController();
  final _deviceIdController = TextEditingController(text: 'ETM_DEV_001');

  @override
  void dispose() {
    _busIdController.dispose();
    _pinController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  void _submitPairing() {
    if (_formKey.currentState?.validate() ?? false) {
      final request = PairingRequest(
        deviceId: _deviceIdController.text.trim(),
        conductorPin: _pinController.text.trim(),
        busId: _busIdController.text.trim(),
      );

      ref.read(authNotifierProvider.notifier).pairOperator(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((session) {
        if (session.isAuthenticated) {
          context.go('/dashboard');
        }
      });
    });

    final isLoading = authState.isLoading;
    final hasError = authState.hasError;

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Operator Pairing'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textSecondary.withAlpha(76),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security,
                        color: AppTheme.accentGreen,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Unpaired',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter Conductor PIN and Bus ID to pair ETM device',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Device ID Field
                Text(
                  'Device Hardware ID',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _deviceIdController,
                  readOnly: true,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.phonelink_setup,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bus ID Field
                Text(
                  'Bus Vehicle ID',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _busIdController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. KA-01-F-1234',
                    prefixIcon: Icon(
                      Icons.directions_bus,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bus ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Conductor PIN Field
                Text(
                  'Conductor Security PIN',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'Enter 4 or 6 digit PIN',
                    prefixIcon: Icon(Icons.pin, color: AppTheme.accentGreen),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 4) {
                      return 'PIN must be at least 4 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                if (hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.accentRed,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pairing failed. Please check PIN and network.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.accentRed,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Button (Min 48dp target)
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitPairing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.primaryBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.primaryBg,
                            ),
                          )
                        : const Text(
                            'PAIR DEVICE & AUTHENTICATE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
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
