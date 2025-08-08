import 'package:be_real/ui/authentication/login_screen.dart';
import 'package:be_real/ui/authentication/splash_screen.dart';
import 'package:be_real/ui/mobile/home_screen.dart';
import 'package:be_real/ui/mobile/user_tasks_screen.dart';
import 'package:be_real/ui/admin/admin_dashboard_screen.dart';
import 'package:be_real/routes/app_routes.dart';
import 'package:get/route_manager.dart';
import 'package:be_real/ui/mobile/monitor_tasks_list_screen.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.splashScreen, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
    GetPage(
      name: AppRoutes.userTasksScreen,
      page: () => const UserTasksScreen(),
    ),
    GetPage(name: AppRoutes.loginScreen, page: () => const LoginScreen()),
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.monitorTodayTasks,
      page: () => const MonitorTasksListScreen(
        title: "Today's Tasks",
        taskType: 'today',
      ),
    ),
    GetPage(
      name: AppRoutes.monitorFutureTasks,
      page: () => const MonitorTasksListScreen(
        title: "Future Tasks",
        taskType: 'future',
      ),
    ),
    GetPage(
      name: AppRoutes.monitorReportedTasks,
      page: () => const MonitorTasksListScreen(
        title: "Reported Tasks",
        taskType: 'reported',
      ),
    ),
    GetPage(
      name: AppRoutes.monitorMissedTasks,
      page: () => const MonitorTasksListScreen(
        title: "Missed Tasks",
        taskType: 'missed',
      ),
    ),
    GetPage(
      name: AppRoutes.monitorToBeUploadedTasks,
      page: () => const MonitorTasksListScreen(
        title: "To Be Uploaded",
        taskType: 'to-upload',
      ),
    ),
  ];
}
