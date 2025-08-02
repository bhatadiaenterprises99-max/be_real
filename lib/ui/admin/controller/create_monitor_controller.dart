import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:be_real/models/site_model.dart';

class CreateMonitorController extends GetxController {
  // Firebase references
  final _firestore = FirebaseFirestore.instance;

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final loadingCompanies = false.obs;
  final loadingSites = false.obs;
  final loadingSitesForCompany = false.obs;
  final passwordVisible = false.obs;
  final checkingUsername = false.obs;
  final usernameAvailable = true.obs;
  final sites = <SiteModel>[].obs;
  final companySites = <SiteModel>[].obs;
  final companies = <Map<String, dynamic>>[].obs;
  final selectedSiteIds = <String>[].obs;
  final selectedCompanyId = ''.obs;

  // Debounce for username check
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    passwordVisible.value = !passwordVisible.value;
  }

  // Fetch companies from Firestore
  Future<void> fetchCompanies() async {
    loadingCompanies.value = true;
    try {
      final snapshot = await _firestore.collection('companies').get();
      companies.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': data['name'] ?? 'Unnamed Company'};
      }).toList();

      // Sort companies by name
      companies.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load companies: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      loadingCompanies.value = false;
    }
  }

  // Select company and fetch its sites
  void selectCompany(String companyId) {
    selectedCompanyId.value = companyId;
    selectedSiteIds.clear();

    if (companyId.isEmpty) {
      companySites.clear();
      return;
    }

    fetchSitesForCompany(companyId);
  }

  // Fetch sites for selected company
  Future<void> fetchSitesForCompany(String companyId) async {
    if (companyId.isEmpty) return;

    loadingSitesForCompany.value = true;
    companySites.clear();

    try {
      final snapshot = await _firestore
          .collection('sites')
          .where('companyId', isEqualTo: companyId)
          .get();

      companySites.value = snapshot.docs
          .map((doc) => SiteModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load sites: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      loadingSitesForCompany.value = false;
    }
  }

  Future<void> fetchSites() async {
    loadingSites.value = true;
    try {
      final snapshot = await _firestore.collection('sites').get();
      sites.value = snapshot.docs
          .map((doc) => SiteModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load sites: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      loadingSites.value = false;
    }
  }

  void checkUsername() {
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      usernameAvailable.value = true;
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) return;

    checkingUsername.value = true;
    try {
      final monitorRef = await _firestore
          .collection('monitors')
          .where('username', isEqualTo: username)
          .get();

      final userRef = await _firestore
          .collection('users')
          .where('userName', isEqualTo: username)
          .get();

      usernameAvailable.value = monitorRef.docs.isEmpty && userRef.docs.isEmpty;
    } catch (e) {
      usernameAvailable.value = false;
      Get.snackbar(
        'Error',
        'Failed to check username availability',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      checkingUsername.value = false;
    }
  }

  // Validation methods
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (!usernameAvailable.value) {
      return 'This username is already taken';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (!GetUtils.isPhoneNumber(value)) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  Future<void> submitMonitorData() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Site selection is optional now

    isLoading.value = true;

    try {
      // Create monitor document in Firestore
      final monitorRef = await _firestore.collection('monitors').add({
        'name': fullNameController.text.trim(),
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'mobile': mobileController.text.trim(),
        'password': passwordController.text,
        'assignedSiteIds': selectedSiteIds,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // If sites were selected, update them with the monitor ID
      if (selectedSiteIds.isNotEmpty) {
        final batch = _firestore.batch();

        for (final siteId in selectedSiteIds) {
          final siteRef = _firestore.collection('sites').doc(siteId);
          batch.update(siteRef, {'monitorId': monitorRef.id});
        }

        await batch.commit();
      }

      Get.snackbar(
        'Success',
        'Monitor account created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _clearForm();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create monitor account: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _clearForm() {
    fullNameController.clear();
    usernameController.clear();
    emailController.clear();
    mobileController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    selectedSiteIds.clear();
    selectedCompanyId.value = '';
    companySites.clear();
    usernameAvailable.value = true;
  }
}
