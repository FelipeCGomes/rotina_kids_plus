import 'package:go_router/go_router.dart';
import 'package:rotina_kids_plus/data/models/calendar_event_model.dart';
import 'package:rotina_kids_plus/data/models/child_model.dart';
import 'package:rotina_kids_plus/data/models/community_models.dart';
import 'package:rotina_kids_plus/data/models/reward_model.dart';
import 'package:rotina_kids_plus/data/models/task_model.dart';
import 'package:rotina_kids_plus/features/child/child_selection_screen.dart';
import 'package:rotina_kids_plus/features/parent/calendar/calendar_screen.dart';
import 'package:rotina_kids_plus/features/parent/calendar/create_event_screen.dart';
import 'package:rotina_kids_plus/features/parent/children/add_child_screen.dart';
import 'package:rotina_kids_plus/features/parent/community/community_screen.dart';
import 'package:rotina_kids_plus/features/parent/community/post_detail_screen.dart';
import 'package:rotina_kids_plus/features/parent/dashboard/approval_screen.dart';
import 'package:rotina_kids_plus/features/parent/rewards/create_reward_screen.dart';
import 'package:rotina_kids_plus/features/parent/rewards/reward_list_screen.dart';
import 'package:rotina_kids_plus/features/parent/routine/create_task_screen.dart';
import 'package:rotina_kids_plus/features/parent/routine/routine_list_screen.dart';
import 'package:rotina_kids_plus/features/parent/rules/rules_screen.dart';
import 'package:rotina_kids_plus/features/parent/screen_time/screen_time_dashboard_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/mode_selection/mode_selection_screen.dart';
import '../../features/parent/dashboard/parent_dashboard_screen.dart';
import '../../features/child/dashboard/child_dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/mode-selection',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: '/parent-home',
      builder: (context, state) => const ParentDashboardScreen(),
    ),
    GoRoute(
      path: '/child-home',
      builder: (context, state) => const ChildDashboardScreen(),
    ),

    GoRoute(
      path: '/add-child',
      builder: (context, state) => const AddChildScreen(),
    ),

    GoRoute(
      path: '/add-child',
      builder: (context, state) {
        final child =
            state.extra
                as ChildModel?; // Se for null, cadastra novo. Se não, edita.
        return AddChildScreen(childToEdit: child);
      },
    ),

    GoRoute(
      path: '/create-task',
      builder: (context, state) {
        final task =
            state.extra as TaskModel?; // Captura a tarefa enviada para edição
        return CreateTaskScreen(taskToEdit: task);
      },
    ),

    GoRoute(
      path: '/routine-list',
      builder: (context, state) => const RoutineListScreen(),
    ),
    GoRoute(
      path: '/reward-list',
      builder: (context, state) => const RewardListScreen(),
    ),
    GoRoute(
      path: '/create-reward',
      builder: (context, state) {
        final reward = state.extra as RewardModel?;
        return CreateRewardScreen(rewardToEdit: reward);
      },
    ),
    GoRoute(
      path: '/approvals',
      builder: (context, state) => const ApprovalScreen(),
    ),
    GoRoute(
      path: '/screen-time',
      builder: (context, state) => const ScreenTimeDashboardScreen(),
    ),

    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/create-event',
      builder: (context, state) {
        // Essa lógica lida com a passagem do dia selecionado OU do evento a ser editado
        if (state.extra is DateTime) {
          return CreateEventScreen(initialDate: state.extra as DateTime);
        } else if (state.extra is Map) {
          final map = state.extra as Map;
          return CreateEventScreen(
            eventToEdit: map['event'] as CalendarEventModel?,
          );
        }
        return const CreateEventScreen();
      },
    ),
    GoRoute(path: '/rules', builder: (context, state) => const RulesScreen()),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/post-details',
      builder: (context, state) {
        final post = state.extra as PostModel;
        return PostDetailScreen(post: post);
      },
    ),

    GoRoute(
      path: '/child-selection',
      builder: (context, state) => const ChildSelectionScreen(),
    ),
  ],
);
