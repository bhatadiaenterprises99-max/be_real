import 'package:be_real/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern AppBar with avatar and actions
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
                          Icons.notifications_none,
                          color: Color(0xFF7F8C8D),
                        ),
                        onPressed: () {},
                        tooltip: 'Notifications',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.help_outline,
                          color: Color(0xFF7F8C8D),
                        ),
                        onPressed: () {},
                        tooltip: 'Help & Support',
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.9,
                  children: [
                    _modernTaskCard(
                      title: "Today's Tasks",
                      count: 5,
                      icon: Icons.today,
                      color: const Color(0xFFEC407A),
                      onTap: () {
                        Get.toNamed(AppRoutes.userTasksScreen);
                      },
                    ),
                    _modernTaskCard(
                      title: 'Future Tasks',
                      count: 0,
                      icon: Icons.calendar_today,
                      color: const Color(0xFFAB47BC),
                    ),
                    _modernTaskCard(
                      title: 'Reported Tasks',
                      count: 0,
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF42A5F5),
                    ),
                    _modernTaskCard(
                      title: 'Missed Tasks',
                      count: 52,
                      icon: Icons.event_busy,
                      color: const Color(0xFFFFA726),
                    ),
                    _modernTaskCard(
                      title: 'To Be Uploaded',
                      count: 0,
                      icon: Icons.cloud_upload_outlined,
                      color: const Color(0xFF26A69A),
                    ),
                  ],
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //   child: Container(
            //     width: double.infinity,
            //     decoration: BoxDecoration(
            //       color: const Color(0xFFE0E7F7),
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //     padding: const EdgeInsets.all(18),
            //     child: const Text(
            //       'Stay productive and keep track of your tasks! 💪',
            //       style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
            //       textAlign: TextAlign.center,
            //     ),
            //   ),
            // ),
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
                    colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
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
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(icon, size: 32, color: Colors.white),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(10),
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
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
