import 'dart:developer';
import 'package:be_real/models/site_model.dart';
import 'package:be_real/models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SiteController extends GetxController {
  // Form controllers
  final companyNameController = TextEditingController();
  final clientNameController = TextEditingController();
  final productNameController = TextEditingController();
  final estimateController = TextEditingController();
  final cityController = TextEditingController();
  final locationController = TextEditingController();
  final supplierController = TextEditingController();
  final campaignController = TextEditingController();
  final processController = TextEditingController();

  // Task form controllers
  final taskTitleController = TextEditingController();
  final taskDescriptionController = TextEditingController();
  final taskDurationController = TextEditingController();

  // Observable data
  final sites = <SiteModel>[].obs;
  final tasks = <TaskModel>[].obs;
  final monitors = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final selectedSite = Rxn<SiteModel>();
  final formKey = GlobalKey<FormState>();
  final taskFormKey = GlobalKey<FormState>();
  final selectedMonitorId = ''.obs;
  final isTaskFormVisible = false.obs;

  // Filter options
  final showReported = false.obs;
  final statusFilter = Rxn<SiteStatus>();

  @override
  void onInit() {
    super.onInit();
    fetchMonitors();
    fetchSites();
  }

  // Monitor methods
  Future<void> fetchMonitors() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'monitor')
          .get();

      monitors.value = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error fetching monitors: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to load monitors',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Site methods
  Future<void> fetchSites() async {
    isLoading.value = true;
    try {
      Query query = FirebaseFirestore.instance.collection('sites');

      // Apply filters
      if (showReported.value) {
        query = query.where('isReported', isEqualTo: true);
      }

      if (statusFilter.value != null) {
        query = query.where('status', isEqualTo: statusFilter.value!.name);
      }

      final snapshot = await query.get();
      sites.value = snapshot.docs
          .map(
            (doc) =>
                SiteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      log('Error fetching sites: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to load sites',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createSite() async {
    if (!formKey.currentState!.validate()) return false;

    isLoading.value = true;
    try {
      final site = SiteModel(
        companyName: companyNameController.text,
        clientName: clientNameController.text,
        productName: productNameController.text,
        estimate: estimateController.text,
        city: cityController.text,
        location: locationController.text,
        supplier: supplierController.text,
        campaign: campaignController.text,
        process: processController.text,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('sites')
          .add(site.toMap());

      final newSite = site.copyWith(id: docRef.id);
      sites.add(newSite);
      selectedSite.value = newSite;

      clearSiteForm();
      Get.snackbar(
        'Success',
        'Site created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      log('Error creating site: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to create site',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSite(SiteModel site) async {
    isLoading.value = true;
    try {
      await FirebaseFirestore.instance
          .collection('sites')
          .doc(site.id)
          .update(site.toMap());

      final index = sites.indexWhere((s) => s.id == site.id);
      if (index != -1) {
        sites[index] = site;
        sites.refresh();
      }

      Get.snackbar(
        'Success',
        'Site updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      log('Error updating site: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to update site',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void selectSite(SiteModel site) {
    selectedSite.value = site;
    fetchTasksForSite(site.id!);
  }

  void clearSiteForm() {
    companyNameController.clear();
    clientNameController.clear();
    productNameController.clear();
    estimateController.clear();
    cityController.clear();
    locationController.clear();
    supplierController.clear();
    campaignController.clear();
    processController.clear();
  }

  // Task methods
  Future<void> fetchTasksForSite(String siteId) async {
    isLoading.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('siteId', isEqualTo: siteId)
          .get();

      tasks.value = snapshot.docs
          .map(
            (doc) =>
                TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      log('Error fetching tasks: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to load tasks',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createTask() async {
    if (!taskFormKey.currentState!.validate() || selectedSite.value == null)
      return false;

    isLoading.value = true;
    try {
      final task = TaskModel(
        siteId: selectedSite.value!.id!,
        title: taskTitleController.text,
        description: taskDescriptionController.text,
        duration: int.tryParse(taskDurationController.text) ?? 0,
        monitorId: selectedMonitorId.value,
        dueDate: DateTime.now().add(
          Duration(days: 7),
        ), // Default due date: 1 week
      );

      final docRef = await FirebaseFirestore.instance
          .collection('tasks')
          .add(task.toMap());

      final newTask = task.copyWith(id: docRef.id);
      tasks.add(newTask);

      clearTaskForm();
      isTaskFormVisible.value = false;
      Get.snackbar(
        'Success',
        'Task created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      log('Error creating task: $e', error: e);
      Get.snackbar(
        'Error',
        'Failed to create task',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void toggleTaskForm() {
    isTaskFormVisible.toggle();
  }

  void clearTaskForm() {
    taskTitleController.clear();
    taskDescriptionController.clear();
    taskDurationController.clear();
    selectedMonitorId.value = '';
  }

  // Filters
  void toggleReportedFilter() {
    showReported.toggle();
    fetchSites();
  }

  void setStatusFilter(SiteStatus? status) {
    statusFilter.value = status;
    fetchSites();
  }

  @override
  void onClose() {
    // Dispose controllers
    companyNameController.dispose();
    clientNameController.dispose();
    productNameController.dispose();
    estimateController.dispose();
    cityController.dispose();
    locationController.dispose();
    supplierController.dispose();
    campaignController.dispose();
    processController.dispose();
    taskTitleController.dispose();
    taskDescriptionController.dispose();
    taskDurationController.dispose();
    super.onClose();
  }
}
