import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:developer';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable statistics
  final approved = 0.obs;
  final rejected = 0.obs;
  final verified = 0.obs;
  final delayed = 0.obs;

  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStatistics();
  }

  Future<void> fetchDashboardStatistics() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      // Get all sites
      final sitesSnapshot = await _firestore.collection('sites').get();

      // Reset counters
      int approvedCount = 0;
      int rejectedCount = 0;
      int verifiedCount = 0;
      int delayedCount = 0;

      final now = DateTime.now();

      for (var doc in sitesSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';

        // Check if site has start and end dates
        final startDate = data['startDate'] is Timestamp
            ? (data['startDate'] as Timestamp).toDate()
            : null;
        final endDate = data['endDate'] is Timestamp
            ? (data['endDate'] as Timestamp).toDate()
            : null;

        // Count approved sites (completed with uploads)
        if (status == 'completed') {
          final monitorUploads =
              data['monitorUploads'] as Map<String, dynamic>? ?? {};
          final hasUploads =
              (monitorUploads['images'] as List?)?.isNotEmpty == true ||
              (monitorUploads['videos'] as List?)?.isNotEmpty == true;

          if (hasUploads) {
            approvedCount++;
          }
        }
        // Count rejected sites
        else if (status == 'rejected') {
          rejectedCount++;
        }
        // Count verified sites (pending/ongoing with uploads)
        else if ((status == 'pending' || status == 'ongoing')) {
          final monitorUploads =
              data['monitorUploads'] as Map<String, dynamic>? ?? {};
          final hasUploads =
              (monitorUploads['images'] as List?)?.isNotEmpty == true ||
              (monitorUploads['videos'] as List?)?.isNotEmpty == true;

          if (hasUploads) {
            verifiedCount++;
          }
        }

        // Count delayed sites (past end date but not completed)
        if (endDate != null && endDate.isBefore(now) && status != 'completed') {
          delayedCount++;
        }
      }

      // Update observable values
      approved.value = approvedCount;
      rejected.value = rejectedCount;
      verified.value = verifiedCount;
      delayed.value = delayedCount;
    } catch (e) {
      log('Error fetching dashboard statistics: $e');
      hasError.value = true;
      errorMessage.value = 'Failed to load statistics: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Method to refresh statistics
  Future<void> refreshStatistics() async {
    await fetchDashboardStatistics();
  }
}
