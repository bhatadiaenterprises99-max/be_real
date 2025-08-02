import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/site_detail_dialog.dart';

class SiteViewController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable states
  final isLoading = false.obs;
  final companies = <Map<String, dynamic>>[].obs;
  final sites = <Map<String, dynamic>>[].obs;
  final selectedCompanyId = ''.obs;

  // Text controller for search functionality
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  // Selected site details
  final selectedSite = Rxn<Map<String, dynamic>>();
  final isLoadingSiteDetails = false.obs;

  // Monitor related fields
  final monitors = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
    fetchMonitors();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Update search query
  void updateSearch(String query) {
    searchQuery.value = query.toLowerCase();
  }

  // Fetch companies from Firestore
  Future<void> fetchCompanies() async {
    try {
      final snapshot = await _firestore.collection('companies').get();
      companies.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Company',
          'contactPerson': data['contactPerson'] ?? '',
          'contactPhone': data['contactPhone'] ?? '',
        };
      }).toList();

      // Sort companies alphabetically by name
      companies.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );

      // Add "All Companies" option at the beginning
      companies.insert(0, {'id': '', 'name': 'All Companies'});
    } catch (e) {
      log('Error fetching companies: $e');

      Get.snackbar(
        'Error',
        'Failed to load companies: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Fetch monitors from Firestore
  Future<void> fetchMonitors() async {
    try {
      final snapshot = await _firestore.collection('monitors').get();
      monitors.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Monitor',
          'username': data['username'] ?? '',
        };
      }).toList();
    } catch (e) {
      log('Error fetching monitors: $e');
    }
  }

  // Fetch sites based on filters
  Future<void> fetchSites({bool onlyActive = false}) async {
    isLoading.value = true;
    sites.clear();

    try {
      Query query = _firestore.collection('sites');

      // Apply company filter if selected
      if (selectedCompanyId.value.isNotEmpty) {
        query = query.where('companyId', isEqualTo: selectedCompanyId.value);
      }

      // Apply status filter for reported sites screen
      if (onlyActive) {
        query = query.where('status', whereNotIn: ['completed', 'expired']);
      }

      // Order by createdAt (latest first)
      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        sites.value = [];
      } else {
        sites.value = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'state': data['state'] ?? '',
            'district': data['district'] ?? '',
            'cityTown': data['cityTown'] ?? '',
            'location': data['location'] ?? '',
            'type': data['type'] ?? '',
            'media': data['media'] ?? '',
            'units': data['units'] ?? '',
            'facia': data['facia'] ?? '',
            'width': data['width'] ?? '',
            'height': data['height'] ?? '',
            'status': data['status'] ?? 'pending',
            'companyId': data['companyId'] ?? '',
            'monitorId': data['monitorId'], // Include monitorId
            'monitorUploads':
                data['monitorUploads'] ??
                {
                  'images': [],
                  'videos': [],
                  'note': '',
                  'latitude': null,
                  'longitude': null,
                },
            'createdAt': data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          };
        }).toList();
      }
    } catch (e) {
      log('Error fetching sites: $e');
      Get.snackbar(
        'Error',
        'Failed to load sites: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Set selected company and refetch sites
  void setSelectedCompany(String id, {bool onlyActive = false}) {
    selectedCompanyId.value = id;
    fetchSites(onlyActive: onlyActive);
  }

  // Get filtered sites based on search query
  List<Map<String, dynamic>> get filteredSites {
    if (searchQuery.isEmpty) return sites;

    return sites.where((site) {
      final location = site['location']?.toString().toLowerCase() ?? '';
      final state = site['state']?.toString().toLowerCase() ?? '';
      final district = site['district']?.toString().toLowerCase() ?? '';
      final cityTown = site['cityTown']?.toString().toLowerCase() ?? '';
      final type = site['type']?.toString().toLowerCase() ?? '';
      final media = site['media']?.toString().toLowerCase() ?? '';

      return location.contains(searchQuery.value) ||
          state.contains(searchQuery.value) ||
          district.contains(searchQuery.value) ||
          cityTown.contains(searchQuery.value) ||
          type.contains(searchQuery.value) ||
          media.contains(searchQuery.value);
    }).toList();
  }

  // Get company name by ID
  String getCompanyName(String companyId) {
    if (companyId.isEmpty) return '';

    final company = companies.firstWhereOrNull((c) => c['id'] == companyId);
    return company != null ? company['name'] : 'Unknown Company';
  }

  // Get monitor name by ID
  String getMonitorName(String monitorId) {
    if (monitorId.isEmpty) return 'Not Assigned';

    final monitor = monitors.firstWhereOrNull((m) => m['id'] == monitorId);
    return monitor != null ? monitor['name'] : 'Unknown Monitor';
  }

  // Get status color
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // View site details
  void viewSiteDetails(String siteId) async {
    isLoadingSiteDetails.value = true;
    try {
      // Find site in existing list first
      final site = sites.firstWhereOrNull((s) => s['id'] == siteId);

      if (site != null) {
        // Show dialog with existing data
        _showSiteDetailDialog(site);
      } else {
        // Fetch from Firestore if not found
        final docSnap = await _firestore.collection('sites').doc(siteId).get();
        if (docSnap.exists) {
          final data = docSnap.data() as Map<String, dynamic>;
          final site = {
            'id': docSnap.id,
            ...data,
            'createdAt': data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          };

          _showSiteDetailDialog(site);
        } else {
          Get.snackbar(
            'Error',
            'Site not found',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      log('Error fetching site details: $e');
      Get.snackbar(
        'Error',
        'Failed to load site details',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoadingSiteDetails.value = false;
    }
  }

  // Fetch specific site data (used after uploads to refresh data)
  Future<void> refreshSiteData(String siteId) async {
    try {
      final docSnap = await _firestore.collection('sites').doc(siteId).get();
      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        final updatedSite = {
          'id': docSnap.id,
          ...data,
          'createdAt': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        };

        // Update site in the sites list if it exists there
        final index = sites.indexWhere((s) => s['id'] == siteId);
        if (index != -1) {
          sites[index] = updatedSite;
          sites.refresh();
        }

        // Show the updated site details
        _showSiteDetailDialog(updatedSite);
      }
    } catch (e) {
      log('Error refreshing site data: $e');
    }
  }

  void _showSiteDetailDialog(Map<String, dynamic> site) {
    final companyName = getCompanyName(site['companyId'] ?? '');
    final statusColor = getStatusColor(site['status'] ?? 'pending');

    Get.dialog(
      SiteDetailDialog(
        site: site,
        companyName: companyName,
        statusColor: statusColor,
      ),
      barrierDismissible: true,
    );
  }

  // Assign monitor to site
  Future<bool> assignMonitorToSite(String siteId, String monitorId) async {
    try {
      // Update site with monitorId
      await _firestore.collection('sites').doc(siteId).update({
        'monitorId': monitorId,
      });

      // Add siteId to monitor's assignedSiteIds
      final monitorRef = _firestore.collection('monitors').doc(monitorId);
      final monitorDoc = await monitorRef.get();

      if (monitorDoc.exists) {
        final List<String> assignedSiteIds = List<String>.from(
          monitorDoc.data()?['assignedSiteIds'] ?? [],
        );

        if (!assignedSiteIds.contains(siteId)) {
          assignedSiteIds.add(siteId);
          await monitorRef.update({'assignedSiteIds': assignedSiteIds});
        }
      }

      // Refresh the sites list to reflect the changes
      await refreshSites();

      Get.snackbar(
        'Success',
        'Monitor assigned successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      log('Error assigning monitor: $e');

      Get.snackbar(
        'Error',
        'Failed to assign monitor: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );

      return false;
    }
  }

  // Add a method to refresh sites data
  Future<void> refreshSites() async {
    final currentOnlyActive =
        sites.isNotEmpty &&
        sites.every(
          (site) =>
              site['status'] != 'completed' && site['status'] != 'expired',
        );

    // Refetch sites with the same filters that were applied
    await fetchSites(onlyActive: currentOnlyActive);
    update(); // Notify all widgets that use GetBuilder to rebuild
  }
}
