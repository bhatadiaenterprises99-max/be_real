import 'package:be_real/routes/app_routes.dart';
import 'package:be_real/utils/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.put(HomeController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE0E7F7),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF7F8C8D),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF7F8C8D),
                        ),
                        onPressed: () => homeController.refreshData(),
                        tooltip: 'Refresh Data',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFF7F8C8D),
                        ),
                        onPressed: () async {
                          await GetStorage().erase();
                          await Helper.clearUserCredential();
                          Get.offAllNamed(AppRoutes.loginScreen);
                        },
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
              child: const Text(
                'Your Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (homeController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: homeController.refreshData,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600
                            ? 3
                            : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: constraints.maxWidth > 600
                              ? 1.0
                              : 0.85,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _modernTaskCard(
                              title: "Today's Tasks",
                              count: homeController.todayTasks.value,
                              icon: Icons.today,
                              color: const Color(0xFFEC407A),
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.userTasksScreen,
                                  arguments: {
                                    'siteId':
                                        homeController.todaySiteIds.isNotEmpty
                                        ? homeController.todaySiteIds[0]
                                        : null,
                                    'taskType': 'today',
                                  },
                                );
                              },
                            ),
                            _modernTaskCard(
                              title: 'Future Tasks',
                              count: homeController.futureTasks.value,
                              icon: Icons.calendar_today,
                              color: const Color(0xFFAB47BC),
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.userTasksScreen,
                                  arguments: {
                                    'siteId':
                                        homeController.futureSiteIds.isNotEmpty
                                        ? homeController.futureSiteIds[0]
                                        : null,
                                    'taskType': 'future',
                                  },
                                );
                              },
                            ),
                            _modernTaskCard(
                              title: 'Reported Tasks',
                              count: homeController.reportedTasks.value,
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF42A5F5),
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.userTasksScreen,
                                  arguments: {
                                    'siteId':
                                        homeController
                                            .reportedSiteIds
                                            .isNotEmpty
                                        ? homeController.reportedSiteIds[0]
                                        : null,
                                    'taskType': 'reported',
                                  },
                                );
                              },
                            ),
                            _modernTaskCard(
                              title: 'Missed Tasks',
                              count: homeController.missedTasks.value,
                              icon: Icons.event_busy,
                              color: const Color(0xFFFFA726),
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.userTasksScreen,
                                  arguments: {
                                    'siteId':
                                        homeController.missedSiteIds.isNotEmpty
                                        ? homeController.missedSiteIds[0]
                                        : null,
                                    'taskType': 'missed',
                                  },
                                );
                              },
                            ),
                            _modernTaskCard(
                              title: 'To Be Uploaded',
                              count: homeController.toBeUploadedTasks.value,
                              icon: Icons.cloud_upload_outlined,
                              color: const Color(0xFF26A69A),
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.userTasksScreen,
                                  arguments: {
                                    'siteId':
                                        homeController
                                            .toBeUploadedSiteIds
                                            .isNotEmpty
                                        ? homeController.toBeUploadedSiteIds[0]
                                        : null,
                                    'taskType': 'toBeUploaded',
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _modernTaskCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 200;
        final fontSize = isSmallScreen ? 14.0 : 16.0;
        final countFontSize = isSmallScreen ? 18.0 : 20.0;
        final iconSize = isSmallScreen ? 28.0 : 32.0;
        final padding = isSmallScreen ? 8.0 : 12.0;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.95, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.85),
                          color.withOpacity(0.65),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(padding),
                            child: Icon(
                              icon,
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: padding),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          SizedBox(height: padding),
                          Container(
                            constraints: BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                              maxWidth: isSmallScreen ? 48 : 60,
                              maxHeight: isSmallScreen ? 48 : 60,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: countFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
