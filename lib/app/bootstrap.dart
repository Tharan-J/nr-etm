import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/diagnostics/app_logger.dart';
import 'app.dart';

Future<void> bootstrap({required String environment}) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AppLogger.init(environment: environment);

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('Unhandled Flutter framework error', details.exception, details.stack);
  };

  runZonedGuarded(
    () {
      runApp(
        const ProviderScope(
          child: EtmApp(),
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      AppLogger.error('Unhandled async error in zone', error, stackTrace);
    },
  );
}
