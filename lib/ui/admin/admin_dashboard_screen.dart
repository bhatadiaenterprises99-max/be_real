import 'package:be_real/ui/admin/create_monitor_screen.dart';
import 'package:be_real/ui/admin/sites/all_sites_screen.dart';
import 'package:be_real/ui/admin/sites/reported_site_screen.dart' as reported_site;
import 'package:be_real/ui/admin/sites/upload_site_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dashboard_cards.dart';

import 'monitors_screen.dart';
import 'profile_screen.dart';

enum AdminNavOption {
  dashboard,
  reportedSite,
  allSites,
  monitors,
  createUserProfile,
  uploadSite, // Add new option
  profile,
  logout,
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  AdminNavOption _selectedOption = AdminNavOption.dashboard;
  bool _drawerOpen = false;
  late AnimationController _drawerController;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _drawerOpen = !_drawerOpen;
      if (_drawerOpen) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  Widget _getContent(AdminNavOption option) {
    switch (option) {
      case AdminNavOption.dashboard:
        return const DashboardCards();
      case AdminNavOption.reportedSite:
        return const reported_site.ReportedSiteScreen();
      case AdminNavOption.allSites:
        return const AllSitesScreen();
      case AdminNavOption.monitors:
        return const MonitorsScreen();
      case AdminNavOption.createUserProfile:
        return const CreateMonitorScreen();
      case AdminNavOption.uploadSite: // Add this case
        return const UploadSiteScreen();
      case AdminNavOption.profile:
        return const ProfileScreen();
      case AdminNavOption.logout:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
        return const Center(child: Text('Logging out...'));
    }
  }

  // ...dashboard card widget moved to dashboard_cards.dart...

  void _onNavSelect(AdminNavOption option) {
    if (option == AdminNavOption.logout) {
      // Show logout dialog or handle logout
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _selectedOption = option;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb && constraints.maxWidth > 700) {
          // Web: Modern sliding drawer nav
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Admin Dashboard',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF232946),
              leading: IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _drawerController,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: _toggleDrawer,
                tooltip: 'Menu',
              ),
              elevation: 0,
            ),
            body: Stack(
              children: [
                // Main content
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.ease,
                  margin: EdgeInsets.only(left: _drawerOpen ? 240 : 0),
                  child: GestureDetector(
                    onTap: () {
                      if (_drawerOpen) _toggleDrawer();
                    },
                    child: Container(
                      height: double.infinity,
                      color: _drawerOpen
                          ? Colors.black.withOpacity(0.04)
                          : Colors.transparent,
                      child: _getContent(_selectedOption),
                    ),
                  ),
                ),
                // Drawer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.ease,
                  left: _drawerOpen ? 0 : -240,
                  top: 0,
                  bottom: 0,
                  child: _buildDrawer(context),
                ),
              ],
            ),
          );
        } else {
          // Mobile: Bottom nav
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
              backgroundColor: Colors.blue,
            ),
            body: _getContent(_selectedOption),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _mobileNavIndex(_selectedOption),
              onTap: (idx) {
                _onNavSelect(_mobileNavOption(idx));
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.report_gmailerrorred_rounded),
                  label: 'Reported',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_rounded),
                  label: 'All Sites',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.monitor_heart_rounded),
                  label: 'Monitors',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
            ),
          );
        }
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Material(
      elevation: 12,
      color: const Color(0xFF232946),
      child: SizedBox(
        width: 240,
        height: MediaQuery.of(context).size.height,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Logo or avatar
                Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      "assets/images/app-logo.png",
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _drawerItem(
                  icon: Icons.dashboard_customize_rounded,
                  label: 'Dashboard',
                  selected: _selectedOption == AdminNavOption.dashboard,
                  onTap: () {
                    _onNavSelect(AdminNavOption.dashboard);
                    _toggleDrawer();
                  },
                ),
                _drawerItem(
                  icon: Icons.report_gmailerrorred_rounded,
                  label: 'Reported Site',
                  selected: _selectedOption == AdminNavOption.reportedSite,
                  onTap: () {
                    _onNavSelect(AdminNavOption.reportedSite);
                    _toggleDrawer();
                  },
                ),
                _drawerItem(
                  icon: Icons.list_alt_rounded,
                  label: 'All Sites',
                  selected: _selectedOption == AdminNavOption.allSites,
                  onTap: () {
                    _onNavSelect(AdminNavOption.allSites);
                    _toggleDrawer();
                  },
                ),
                _drawerItem(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Monitors',
                  selected: _selectedOption == AdminNavOption.monitors,
                  onTap: () {
                    _onNavSelect(AdminNavOption.monitors);
                    _toggleDrawer();
                  },
                ),
                _drawerItem(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Create User',
                  selected: _selectedOption == AdminNavOption.createUserProfile,
                  onTap: () {
                    _onNavSelect(AdminNavOption.createUserProfile);
                    _toggleDrawer();
                  },
                ),
                _drawerItem(
                  icon: Icons.upload_file,
                  label: 'Upload Sites',
                  selected: _selectedOption == AdminNavOption.uploadSite,
                  onTap: () {
                    _onNavSelect(AdminNavOption.uploadSite);
                    _toggleDrawer();
                  },
                ),
                const SizedBox(height: 24),
                Divider(
                  color: Colors.white24,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                _drawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  selected: _selectedOption == AdminNavOption.logout,
                  onTap: () {
                    _onNavSelect(AdminNavOption.logout);
                    _toggleDrawer();
                  },
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Row(
              children: [
                Icon(icon, color: color ?? Colors.white, size: 26),
                const SizedBox(width: 18),
                Text(
                  label,
                  style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for web nav
  int _webNavIndex(AdminNavOption option) {
    switch (option) {
      case AdminNavOption.dashboard:
        return 0;
      case AdminNavOption.reportedSite:
        return 1;
      case AdminNavOption.allSites:
        return 2;
      case AdminNavOption.monitors:
        return 3;
      case AdminNavOption.createUserProfile:
        return 4;
      case AdminNavOption.uploadSite:
        return 5;
      case AdminNavOption.logout:
        return 6;
      default:
        return 0;
    }
  }

  AdminNavOption _webNavOption(int idx) {
    switch (idx) {
      case 0:
        return AdminNavOption.dashboard;
      case 1:
        return AdminNavOption.reportedSite;
      case 2:
        return AdminNavOption.allSites;
      case 3:
        return AdminNavOption.monitors;
      case 4:
        return AdminNavOption.createUserProfile;
      case 5:
        return AdminNavOption.uploadSite;
      case 6:
        return AdminNavOption.logout;
      default:
        return AdminNavOption.dashboard;
    }
  }

  // Helper for mobile nav
  int _mobileNavIndex(AdminNavOption option) {
    switch (option) {
      case AdminNavOption.dashboard:
        return 0;
      case AdminNavOption.reportedSite:
        return 1;
      case AdminNavOption.allSites:
        return 2;
      case AdminNavOption.monitors:
        return 3;
      case AdminNavOption.profile:
        return 4;
      default:
        return 0;
    }
  }

  AdminNavOption _mobileNavOption(int idx) {
    switch (idx) {
      case 0:
        return AdminNavOption.dashboard;
      case 1:
        return AdminNavOption.reportedSite;
      case 2:
        return AdminNavOption.allSites;
      case 3:
        return AdminNavOption.monitors;
      case 4:
        return AdminNavOption.profile;
      default:
        return AdminNavOption.dashboard;
    }
  }
}
