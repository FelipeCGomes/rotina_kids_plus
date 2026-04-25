import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/parent/parent_home_screen.dart';
import '../../features/child/child_home_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String parentHome = '/parent-home';
  static const String childHome = '/child-home';
  

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    parentHome: (context) => const ParentHomeScreen(),
    childHome: (context) => const ChildHomeScreen(),

  };
}
