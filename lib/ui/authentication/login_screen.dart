import 'package:be_real/routes/app_routes.dart';
import 'package:be_real/ui/authentication/controller/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/common_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final AuthController authController = Get.put(AuthController());
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    // Example admin credentials (replace with secure check in production)
    const adminusername = 'admin@admin.com';
    const adminPassword = 'admin123';
    final inputUsername = _usernameController.text.trim();
    final inputPassword = _passwordController.text.trim();

    if (kIsWeb) {
      if (inputUsername == adminusername && inputPassword == adminPassword) {
        // Navigate to admin dashboard on web
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        // Block non-admin users on web
        Get.snackbar(
          'Access Denied',
          'This app is only accessible to admin on web.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      if (inputUsername.isEmpty || inputPassword.isEmpty) {
        Get.snackbar(
          'Login Failed',
          'Please enter both username and password.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      // Use the injected instance, not a new one
      authController.monitorLogin(inputUsername, inputPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or App Name
                  Center(
                    child: Text(
                      "Sign In",

                      // style: TextStyle(
                      //   fontSize: 26,
                      //   fontWeight: FontWeight.bold,
                      // ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Login using admin provided credentials",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),

                    // style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),
                  // username Field
                  TextField(
                    controller: _usernameController,

                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.blueAccent.withOpacity(0.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.blueAccent.withOpacity(0.6),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.blueAccent.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login Button
                  Obx(
                    () => ElevatedButton(
                      onPressed: authController.isLoading.value
                          ? null
                          : _onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: Colors.blueAccent.withOpacity(0.3),
                      ),
                      child: authController.isLoading.value
                          ? CircularProgressIndicator()
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  // const SizedBox(height: 16),
                  // // Forgot Password
                  // TextButton(
                  //   onPressed: () {},
                  //   child: Text(
                  //     'Contact Admin for Password',
                  //     style: TextStyle(
                  //       color: Colors.blueAccent.withOpacity(0.8),
                  //       fontSize: 14,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
