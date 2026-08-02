import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class EtmApp extends StatelessWidget {
  const EtmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NammaRoute ETM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
