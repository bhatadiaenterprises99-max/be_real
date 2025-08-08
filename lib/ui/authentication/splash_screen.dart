import 'package:be_real/utils/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:be_real/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Using Future.delayed to ensure navigation happens after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkUserLogin();
    });
  }

  void checkUserLogin() async {
    String? userId = Helper.getUserCredential();
    print("User id $userId");
    if (userId == null) {
      Get.offAllNamed(AppRoutes.loginScreen);
    } else {
      if (kIsWeb) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset("assets/images/app-logo.png", width: 400),
      ),
    );
  }
}
