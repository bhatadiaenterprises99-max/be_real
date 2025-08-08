import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:be_real/utils/get_storage.dart';

class HomeController extends GetxController {
  final _firestore = FirebaseFirestore.instance;

  // Observable variables for task counts
  final todayTasks = 0.obs;
  final futureTasks = 0.obs;
  final reportedTasks = 0.obs;
  final missedTasks = 0.obs;
  final toBeUploadedTasks = 0.obs;

  // Track site IDs for each category
  final todaySiteIds = <String>[].obs;
  final futureSiteIds = <String>[].obs;
  final reportedSiteIds = <String>[].obs;
  final missedSiteIds = <String>[].obs;
  final toBeUploadedSiteIds = <String>[].obs;

  // Loading state
  final isLoading = true.obs;

  // Current monitor ID
  String? monitorId;

  // Sites assigned to this monitor
  final assignedSiteIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMonitorData();
  }

  Future<void> loadMonitorData() async {
    isLoading.value = true;
    try {
      // Get monitor ID from local storage
      final userId = await Helper.getUserCredential();
      if (userId == null) {
        print('No monitor ID found in local storage');
        isLoading.value = false;
        return;
      }
      monitorId = userId;

      // Fetch monitor data to get assigned sites
      final monitorDoc = await _firestore
          .collection('monitors')
          .doc(monitorId)
          .get();

      if (!monitorDoc.exists) {
        print('Monitor document not found');
        isLoading.value = false;
        return;
      }

      // Get assigned site IDs
      List<String> siteIds = List<String>.from(
        monitorDoc.data()?['assignedSiteIds'] ?? [],
      );
      assignedSiteIds.value = siteIds;

      await fetchSitesData();
    } catch (e) {
      print('Error loading monitor data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSitesData() async {
    if (assignedSiteIds.isEmpty) {
      print('No assigned sites for this monitor');
      return;
    }

    try {
      // Get today's date (start and end)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Counters for different task categories
      int todayCount = 0;
      int future = 0;
      int reported = 0;
      int missed = 0;
      int toBeUploaded = 0;

      // Clear previous site IDs
      todaySiteIds.clear();
      futureSiteIds.clear();
      reportedSiteIds.clear();
      missedSiteIds.clear();
      toBeUploadedSiteIds.clear();

      // Fetch sites with monitorId field matching current user
      final sitesQuery = await _firestore
          .collection('sites')
          .where('monitorId', isEqualTo: monitorId)
          .get();

      for (var doc in sitesQuery.docs) {
        final site = doc.data();
        final siteId = doc.id;
        final status = site['status'] as String? ?? 'pending';
        final monitorUploads =
            site['monitorUploads'] as Map<String, dynamic>? ?? {};

        // Count by status and other conditions
        if (status == 'pending' || status == 'ongoing') {
          // Site needs work - check if it has uploads
          final hasUploads =
              (monitorUploads['images'] as List?)?.isNotEmpty == true ||
              (monitorUploads['videos'] as List?)?.isNotEmpty == true;

          if (!hasUploads) {
            // No uploads yet - this needs to be uploaded
            toBeUploaded++;
            toBeUploadedSiteIds.add(siteId);
          }

          // Check dates (for simplicity, assuming all active sites are either today or future)
          // In a real app, you would have specific due dates to check against
          if (todayCount % 2 == 0) {
            // Just for demo, alternate between today and future
            todayCount++;
            todaySiteIds.add(siteId);
          } else {
            future++;
            futureSiteIds.add(siteId);
          }
        } else if (status == 'completed') {
          // Count as reported
          reported++;
          reportedSiteIds.add(siteId);
        } else if (status == 'expired') {
          // Count as missed
          missed++;
          missedSiteIds.add(siteId);
        }
      }

      // Update the observable values
      todayTasks.value = todayCount;
      futureTasks.value = future;
      reportedTasks.value = reported;
      missedTasks.value = missed;
      toBeUploadedTasks.value = toBeUploaded;
    } catch (e) {
      print('Error fetching sites data: $e');
    }
  }

  // Refresh data (can be called from pull-to-refresh)
  Future<void> refreshData() async {
    await loadMonitorData();
  }
}
