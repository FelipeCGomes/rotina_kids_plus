import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/profile_mode/choose_mode_screen.dart';
import '../../features/parent/parent_home_screen.dart';
import '../../features/parent/routine/task_form_screen.dart';
import '../../features/parent/rewards/rewards_screen.dart';
import '../../features/parent/screen_time/screen_rules_screen.dart';
import '../../features/child/child_home_screen.dart';
import '../../features/child/child_rewards_store_screen.dart';
import '../../features/child/child_block_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String chooseMode = '/choose-mode';
  static const String parentHome = '/parent-home';
  static const String taskForm = '/task-form';
  static const String rewards = '/rewards';
  static const String screenRules = '/screen-rules';
  static const String childHome = '/child-home';
  static const String childStore = '/child-store';
  static const String childBlock = '/child-block';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    welcome: (context) => const WelcomeScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    chooseMode: (context) => const ChooseModeScreen(),
    parentHome: (context) => const ParentHomeScreen(),
    taskForm: (context) => const TaskFormScreen(),
    rewards: (context) => const RewardsScreen(),
    screenRules: (context) => const ScreenRulesScreen(),
    childHome: (context) => const ChildHomeScreen(),
    childStore: (context) => const ChildRewardsStoreScreen(),
    childBlock: (context) => const ChildBlockScreen(),
  };
}
