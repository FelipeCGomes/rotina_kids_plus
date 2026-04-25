import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rotina_kids_plus/core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/mock_data_repository.dart';

class RotinaKidsApp extends StatelessWidget {
  const RotinaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataRepository()),
      ],
      child: MaterialApp(
        title: 'Rotina Kids+',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}