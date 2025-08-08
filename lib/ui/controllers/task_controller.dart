import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:be_real/utils/get_storage.dart';

class TaskController extends GetxController {
  final _firestore = FirebaseFirestore.instance;

  // Observable variables to hold task data
  final taskData = Rx<Map<String, dynamic>>({});
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // New list to hold all assigned sites data
  final assignedSites = <Map<String, dynamic>>[].obs;

  final companyData = Rx<Map<String, dynamic>>({});

  Future<void> loadMonitorSites() async {
    isLoading.value = true;
    hasError.value = false;
    assignedSites.clear();

    const int maxRetries = 3;
    const Duration baseDelay = Duration(milliseconds: 500);
    const int batchSize = 10; // Firestore whereIn limit is 10 IDs per query

    try {
      // Get monitor ID from local storage
      final monitorId = await Helper.getUserCredential();
      if (monitorId == null) {
        hasError.value = true;
        errorMessage.value = 'User not logged in';
        return;
      }

      // Fetch monitor data to get assignedSiteIds
      final monitorDoc = await _retryOperation(
        () => _firestore.collection('monitors').doc(monitorId).get(),
        maxRetries,
        baseDelay,
        'fetching monitor data',
      );

      if (!monitorDoc.exists) {
        hasError.value = true;
        errorMessage.value = 'Monitor data not found';
        return;
      }

      final monitorData = monitorDoc.data() ?? {};
      final List<String> assignedSiteIds = List<String>.from(
        monitorData['assignedSiteIds'] ?? [],
      );

      if (assignedSiteIds.isEmpty) {
        return;
      }

      // Batch fetch sites using whereIn
      final List<Map<String, dynamic>> sitesData = [];
      for (int i = 0; i < assignedSiteIds.length; i += batchSize) {
        final batchIds = assignedSiteIds.sublist(
          i,
          i + batchSize > assignedSiteIds.length
              ? assignedSiteIds.length
              : i + batchSize,
        );

        try {
          final sitesSnapshot = await _retryOperation(
            () => _firestore
                .collection('sites')
                .where(FieldPath.documentId, whereIn: batchIds)
                .get(),
            maxRetries,
            baseDelay,
            'fetching batch of sites',
          );

          for (var siteDoc in sitesSnapshot.docs) {
            if (siteDoc.exists) {
              final siteData = siteDoc.data();
              siteData['id'] = siteDoc.id;
              sitesData.add(siteData);
            }
          }
        } catch (e) {
          print('Error fetching batch of sites: $e');
        }
      }

      // Fetch company data for all sites
      final companyIds = sitesData
          .where((site) => site['companyId'] != null)
          .map((site) => site['companyId'] as String)
          .toSet()
          .toList();

      if (companyIds.isNotEmpty) {
        for (int i = 0; i < companyIds.length; i += batchSize) {
          final batchCompanyIds = companyIds.sublist(
            i,
            i + batchSize > companyIds.length
                ? companyIds.length
                : i + batchSize,
          );

          try {
            final companiesSnapshot = await _retryOperation(
              () => _firestore
                  .collection('companies')
                  .where(FieldPath.documentId, whereIn: batchCompanyIds)
                  .get(),
              maxRetries,
              baseDelay,
              'fetching batch of companies',
            );

            final companyDataMap = {
              for (var doc in companiesSnapshot.docs) doc.id: doc.data(),
            };

            // Attach company data to corresponding sites
            for (var siteData in sitesData) {
              if (siteData['companyId'] != null &&
                  companyDataMap.containsKey(siteData['companyId'])) {
                final companyInfo = companyDataMap[siteData['companyId']]!;
                siteData['companyName'] = companyInfo['name'];
                siteData['companyContactPerson'] = companyInfo['contactPerson'];
                siteData['companyContactNumber'] = companyInfo['contactNumber'];
              }
            }
          } catch (e) {
            print('Error fetching batch of company data: $e');
          }
        }
      }

      assignedSites.addAll(sitesData);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load assigned sites: $e';
      print('Error loading assigned sites: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper function for retrying Firestore operations
  Future<T> _retryOperation<T>(
    Future<T> Function() operation,
    int maxRetries,
    Duration baseDelay,
    String operationName,
  ) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        if (e.toString().contains('cloud_firestore/unavailable') &&
            attempt < maxRetries) {
          attempt++;
          final delay = baseDelay * pow(2, attempt); // Exponential backoff
          print(
            'Retrying $operationName after ${delay.inMilliseconds}ms (attempt $attempt/$maxRetries)',
          );
          await Future.delayed(delay);
        } else {
          rethrow;
        }
      }
    }
  }

  // Load specific site data by ID
  Future<void> loadTaskData(String siteId) async {
    isLoading.value = true;
    hasError.value = false;

    try {
      final docRef = await _firestore.collection('sites').doc(siteId).get();

      if (docRef.exists) {
        final data = docRef.data() ?? {};
        taskData.value = data;

        // Fetch associated company data
        if (data['companyId'] != null) {
          await loadCompanyData(data['companyId']);
        }
      } else {
        hasError.value = true;
        errorMessage.value = 'Site not found';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load site data: $e';
      print('Error loading site data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load company data by company ID
  Future<void> loadCompanyData(String companyId) async {
    try {
      final companyDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();

      if (companyDoc.exists) {
        companyData.value = companyDoc.data() ?? {};
      }
    } catch (e) {
      print('Error loading company data: $e');
    }
  }

  // Helper function to get formatted value with fallback
  String getValue(String key, {String defaultValue = 'Not available'}) {
    return taskData.value[key]?.toString() ?? defaultValue;
  }

  // Get company value
  String getCompanyValue(String key, {String defaultValue = 'Not available'}) {
    return companyData.value[key]?.toString() ?? defaultValue;
  }

  // Get site value by ID and key
  String getSiteValue(
    String siteId,
    String key, {
    String defaultValue = 'Not available',
  }) {
    final site = assignedSites.firstWhereOrNull((s) => s['id'] == siteId);
    return site?[key]?.toString() ?? defaultValue;
  }

  // Get media uploads
  List<String> getMediaUrls() {
    final uploads =
        taskData.value['monitorUploads'] as Map<String, dynamic>? ?? {};
    final images = uploads['images'] as List? ?? [];
    return images.map((e) => e.toString()).toList();
  }

  // Get site media uploads by ID
  List<String> getSiteMediaUrls(String siteId) {
    final site = assignedSites.firstWhereOrNull((s) => s['id'] == siteId);
    if (site == null) return [];

    final uploads = site['monitorUploads'] as Map<String, dynamic>? ?? {};
    final images = uploads['images'] as List? ?? [];
    return images.map((e) => e.toString()).toList();
  }

  // Get campaign status
  String getStatus() {
    return taskData.value['status']?.toString() ?? 'pending';
  }

  // Get site status by ID
  String getSiteStatus(String siteId) {
    final site = assignedSites.firstWhereOrNull((s) => s['id'] == siteId);
    return site?['status']?.toString() ?? 'pending';
  }

  // Get formatted dates
  String getStartDate() {
    final timestamp = taskData.value['startDate'] as Timestamp?;
    if (timestamp == null) return 'Not set';

    final date = timestamp.toDate();
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String getEndDate() {
    final timestamp = taskData.value['endDate'] as Timestamp?;
    if (timestamp == null) return 'Not set';

    final date = timestamp.toDate();
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String getTaskDate() {
    final timestamp = taskData.value['taskDate'] as Timestamp?;
    if (timestamp == null) return 'Not set';

    final date = timestamp.toDate();
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  // Get created date
  String getCreatedDate() {
    final timestamp = taskData.value['createdAt'] as Timestamp?;
    if (timestamp == null) return 'Not set';

    final date = timestamp.toDate();
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  // Get company name
  String getCompanyName() {
    return companyData.value['name']?.toString() ?? 'Unknown Company';
  }

  // Helper for month name
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
