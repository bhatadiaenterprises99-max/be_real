import 'package:be_real/routes/app_routes.dart';
import 'package:be_real/utils/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final isLoading = false.obs;
  Future<void> monitorLogin(String username, String password) async {
    isLoading.value = true;
    try {
      final monitor = await _firestore
          .collection('monitors')
          .where('username', isEqualTo: username.trim())
          .get();
      print('Found monitors: ${monitor.docs.length}');

      final users = await _firestore.collection('users').get();
      print('Found users: ${users.docs.length}');

      if (monitor.docs.isNotEmpty) {
        final user = monitor.docs.first;
        if (user['password'] == password.trim()) {
          await Helper.setUserCredential(user.id);
          Get.offAllNamed(AppRoutes.home);
          Get.snackbar('Login Successful', 'Welcome back, $username!');
        } else {
          Get.snackbar('Login Failed', 'Invalid username or password');
        }
      } else {
        Get.snackbar('Login Failed', 'Invalid username or password');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during login');
    } finally {
      isLoading.value = false;
    }
  }
}
