import 'package:be_real/ui/authentication/login_screen.dart';
import 'package:be_real/ui/mobile/home_screen.dart';
import 'package:be_real/ui/mobile/user_tasks_screen.dart';
import 'package:be_real/ui/admin/admin_dashboard_screen.dart';
import 'package:be_real/routes/app_routes.dart';
import 'package:get/route_manager.dart';

class AppPages {
  static final routes = [
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
  ];
}
