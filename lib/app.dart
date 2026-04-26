import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';

class RotinaKidsApp extends StatelessWidget {
  const RotinaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rotina Kids+',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // O tema de alto contraste pode ser ativado dinamicamente depois via Riverpod
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
