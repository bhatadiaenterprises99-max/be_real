import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:be_real/ui/admin/controller/create_user_profile_controller.dart';

class MonitorsController extends GetxController {
  final usersList = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void updateSearch(String query) {
    searchQuery.value = query.toLowerCase();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('monitors')
          .get();
      usersList.value = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error fetching users: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to load users. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    if (searchQuery.isEmpty) return usersList;

    return usersList.where((user) {
      final fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
          .toLowerCase();
      final username = (user['userName'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final phone = (user['phone'] ?? '').toLowerCase();

      return fullName.contains(searchQuery) ||
          username.contains(searchQuery) ||
          email.contains(searchQuery) ||
          phone.contains(searchQuery);
    }).toList();
  }

  Future<void> resetPassword(
    String userId,
    String firstName,
    String phone,
  ) async {
    try {
      final createController = Get.find<CreateUserProfileController>();
      final newPassword = createController.generatePassword(firstName, phone);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'password': newPassword,
      });

      Get.snackbar(
        'Success',
        'Password has been reset successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log('Error resetting password: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to reset password. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': !currentStatus,
      });

      // Update local list
      final index = usersList.indexWhere((user) => user['id'] == userId);
      if (index != -1) {
        usersList[index]['isActive'] = !currentStatus;
        usersList.refresh();
      }

      Get.snackbar(
        'Success',
        'User status updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log('Error toggling user status: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to update user status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void navigateToEditUser(Map<String, dynamic> user) {
    // Implement navigation to edit user screen
    // This will be implemented when the edit user screen is created
    // Get.toNamed('/admin/edit-user', arguments: user);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
