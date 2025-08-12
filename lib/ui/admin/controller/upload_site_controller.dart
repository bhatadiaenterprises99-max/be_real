import 'dart:typed_data';
import 'package:be_real/ui/admin/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadSiteController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final companyNameController = TextEditingController();
  final contactPersonController = TextEditingController();
  final contactNumberController = TextEditingController();

  // Observable variables
  final companies = <Map<String, dynamic>>[].obs;
  final selectedCompanyId = ''.obs;
  final showNewCompanyForm = false.obs;

  final selectedFileName = ''.obs;
  final selectedFileBytes = Rxn<Uint8List>();

  final isLoadingPreview = false.obs;
  final isUploading = false.obs;
  final dataPreviewReady = false.obs;

  final parsedSites = <Map<String, dynamic>>[].obs;
  final uploadProgress = 0.obs;
  final totalSites = 0.obs;
  final processedSites = 0.obs;

  // Add these new properties for date selection
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
  }

  @override
  void onClose() {
    companyNameController.dispose();
    contactPersonController.dispose();
    contactNumberController.dispose();
    super.onClose();
  }

  // Company selection handler
  void onCompanySelected(String? companyId) {
    if (companyId == null) return;

    selectedCompanyId.value = companyId;
    showNewCompanyForm.value = companyId == 'new';

    // If an existing company is selected, make sure to clear the new company form
    if (companyId != 'new') {
      companyNameController.clear();
      contactPersonController.clear();
      contactNumberController.clear();
    }
  }

  // Fetch companies from Firestore
  Future<void> fetchCompanies() async {
    try {
      final snapshot = await _firestore.collection('companies').get();
      companies.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'contactPerson': data['contactPerson'] ?? '',
          'contactNumber': data['contactNumber'] ?? '',
        };
      }).toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load companies: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // File selection handler
  Future<void> pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        selectedFileName.value = result.files.single.name;

        // Platform-agnostic way to get file bytes
        if (result.files.single.bytes != null) {
          // Web platform already provides bytes
          selectedFileBytes.value = result.files.single.bytes;
        } else if (result.files.single.path != null) {
          // Mobile/Desktop platforms provide a file path
          // We would need to read the file, but for now we'll just handle web
          // You may need to add the 'dart:io' import and use File class here
          // for non-web platforms if needed
        }

        dataPreviewReady.value = false;
        parsedSites.clear();
      }
    } catch (e) {
      print('Error picking file: $e');
      Get.snackbar(
        'Error',
        'Failed to pick file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void clearSelectedFile() {
    selectedFileName.value = '';
    selectedFileBytes.value = null;
    dataPreviewReady.value = false;
    parsedSites.clear();
  }

  // Preview Excel data
  Future<void> previewExcelData() async {
    if (selectedFileBytes.value == null) return;

    isLoadingPreview.value = true;
    dataPreviewReady.value = false;
    parsedSites.clear();

    try {
      final bytes = selectedFileBytes.value!;
      final excel = Excel.decodeBytes(bytes);

      // Get the first sheet
      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in the Excel file');
      }

      final sheet = excel.tables[excel.tables.keys.first]!;

      // Parse data from rows
      final List<Map<String, dynamic>> sites = [];

      // Skip the header row
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);

        // Skip empty rows
        if (row.isEmpty || row[0]?.value == null) continue;

        // Map columns to site data
        final site = _parseSiteRow(row);
        if (site != null) {
          sites.add(site);
        }
      }

      parsedSites.value = sites;
      dataPreviewReady.value = true;

      if (sites.isEmpty) {
        Get.snackbar(
          'Warning',
          'No valid site data found in the Excel file',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Success',
          '${sites.length} sites found in the Excel file',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to parse Excel data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoadingPreview.value = false;
    }
  }

  Map<String, dynamic>? _parseSiteRow(List<dynamic> row) {
    try {
      // Expected column indexes (adjust based on your Excel file structure)
      // Sr NO., State, District, City/Town, Media, Location, Type, Units, Facia, W, H
      final srNo = _getCellValue(row, 0);
      final state = _getCellValue(row, 1);
      final district = _getCellValue(row, 2);
      final cityTown = _getCellValue(row, 3);
      final media = _getCellValue(row, 4);
      final location = _getCellValue(row, 5);
      final type = _getCellValue(row, 6);
      final units = _getCellValue(row, 7);
      final facia = _getCellValue(row, 8);
      final width = _getCellValue(row, 9);
      final height = _getCellValue(row, 10);

      // Skip rows with missing essential data
      if (district.isEmpty || cityTown.isEmpty || location.isEmpty) {
        return null;
      }

      // Generate a unique site code
      final siteCode = '${district}_${cityTown}_${location}'
          .replaceAll(' ', '_')
          .toLowerCase();

      return {
        'srNo': srNo,
        'state': state,
        'district': district,
        'cityTown': cityTown,
        'media': media,
        'location': location,
        'type': type,
        'units': units,
        'facia': facia,
        'width': width,
        'height': height,
        'siteCode': siteCode,
      };
    } catch (e) {
      print('Error parsing row: $e');
      return null;
    }
  }

  String _getCellValue(List<dynamic> row, int index) {
    if (index >= row.length || row[index]?.value == null) {
      return '';
    }

    final value = row[index]!.value;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  // Add this method to validate and format dates
  String? validateDates() {
    if (startDate.value == null) {
      return 'Start date is required';
    }

    if (endDate.value == null) {
      return 'End date is required';
    }

    if (endDate.value!.isBefore(startDate.value!)) {
      return 'End date must be after start date';
    }

    return null;
  }

  // Upload sites to Firestore
  Future<void> uploadSites() async {
    // Validate company selection
    if (selectedCompanyId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a company or create a new one',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Validate new company form if "Add New Company" is selected
    if (selectedCompanyId.value == 'new') {
      if (companyNameController.text.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter a company name',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
    }

    // Confirm upload
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Upload'),
        content: Text(
          'Are you sure you want to upload ${parsedSites.length} sites to Firebase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('UPLOAD'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isUploading.value = true;
    String actualCompanyId = selectedCompanyId.value;

    try {
      // If adding a new company, create it first
      if (selectedCompanyId.value == 'new') {
        final companyRef = await _firestore.collection('companies').add({
          'name': companyNameController.text.trim(),
          'contactPerson': contactPersonController.text.trim(),
          'contactNumber': contactNumberController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        actualCompanyId = companyRef.id;

        // Add the new company to our local list
        companies.add({
          'id': actualCompanyId,
          'name': companyNameController.text.trim(),
          'contactPerson': contactPersonController.text.trim(),
          'contactNumber': contactNumberController.text.trim(),
        });
      }

      // Reset progress tracking
      totalSites.value = parsedSites.length;
      processedSites.value = 0;

      // Fetch existing sites to check for duplicates
      final existingSites = await _fetchExistingSitesCodes(actualCompanyId);
      final duplicates = <String>[];
      final newSites = <Map<String, dynamic>>[];

      // Check for duplicates
      for (final site in parsedSites) {
        final siteCode = site['siteCode'] as String;
        if (existingSites.contains(siteCode)) {
          duplicates.add(siteCode);
        } else {
          newSites.add(site);
        }
      }

      // Default dates if not set elsewhere
      final defaultStartDate = startDate.value ?? DateTime.now();
      final defaultEndDate =
          endDate.value ??
          DateTime.now().add(const Duration(days: 30)); // Default 30 days

      // Upload sites in batches to avoid overloading Firestore
      const batchSize = 20;
      for (int i = 0; i < newSites.length; i += batchSize) {
        final batch = _firestore.batch();

        final end = (i + batchSize < newSites.length)
            ? i + batchSize
            : newSites.length;
        final chunk = newSites.sublist(i, end);

        for (final site in chunk) {
          final docRef = _firestore.collection('sites').doc();
          batch.set(docRef, {
            'companyId': actualCompanyId,
            'state': site['state'] ?? '',
            'district': site['district'] ?? '',
            'cityTown': site['cityTown'] ?? '',
            'media': site['media'] ?? '',
            'location': site['location'] ?? '',
            'type': site['type'] ?? '',
            'units': site['units'] ?? '',
            'facia': site['facia'] ?? '',
            'width': site['width'] ?? '',
            'height': site['height'] ?? '',
            'siteCode': site['siteCode'] ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending', // Default status
            'startDate': defaultStartDate, // Add start date
            'endDate': defaultEndDate, // Add end date
            'monitorUploads': {
              'images': [], // List of Firebase Storage URLs
              'videos': [], // List of Firebase Storage URLs
              'note': '', // Optional site note
              'latitude': null,
              'longitude': null,
            },
          });
        }

        await batch.commit();
        processedSites.value += chunk.length;
        uploadProgress.value = (processedSites.value / totalSites.value * 100)
            .round();
      }

      // Show success message with info about duplicates if any
      if (duplicates.isEmpty) {
        Get.snackbar(
          'Success',
          'Uploaded ${newSites.length} sites successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Partial Success',
          'Uploaded ${newSites.length} sites. Skipped ${duplicates.length} duplicates.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }

      // Reset the form if upload was successful
      if (newSites.isNotEmpty) {
        _resetForm(keepCompany: true);
      }

      // Refresh dashboard statistics
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshStatistics();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload sites: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  Future<Set<String>> _fetchExistingSitesCodes(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('sites')
          .where('companyId', isEqualTo: companyId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['siteCode'] as String)
          .toSet();
    } catch (e) {
      print('Error fetching existing sites: $e');
      return {};
    }
  }

  void _resetForm({bool keepCompany = false}) {
    if (!keepCompany) {
      selectedCompanyId.value = '';
      showNewCompanyForm.value = false;
      companyNameController.clear();
      contactPersonController.clear();
      contactNumberController.clear();
    }

    selectedFileName.value = '';
    selectedFileBytes.value = null;
    dataPreviewReady.value = false;
    parsedSites.clear();
  }
}
