import 'package:flutter/material.dart';

class DashboardCards extends StatelessWidget {
  const DashboardCards({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive: 2 columns on web, 1 on mobile
    final isWide = MediaQuery.of(context).size.width > 700;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.1,
        ),
        children: const [
          _MiniDashboardCard(
            icon: Icons.verified,
            title: 'Approved',
            count: 42,
            gradient: LinearGradient(
              colors: [Color(0xFF4F8FFF), Color(0xFF6DD5FA)],
            ),
          ),
          _MiniDashboardCard(
            icon: Icons.cancel_rounded,
            title: 'Rejected',
            count: 7,
            gradient: LinearGradient(
              colors: [Color(0xFFFF5E62), Color(0xFFFF9966)],
            ),
          ),
          _MiniDashboardCard(
            icon: Icons.verified_user,
            title: 'Verified',
            count: 18,
            gradient: LinearGradient(
              colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
            ),
          ),
          _MiniDashboardCard(
            icon: Icons.report_problem_rounded,
            title: 'Delayed',
            count: 3,
            gradient: LinearGradient(
              colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final LinearGradient gradient;

  const _MiniDashboardCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
