import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonitorAssignmentDialog extends StatefulWidget {
  final String siteId;
  final String? currentMonitorId;
  final Function(String monitorId) onAssign;
  final VoidCallback? onRefresh; // Add this callback

  const MonitorAssignmentDialog({
    Key? key,
    required this.siteId,
    this.currentMonitorId,
    required this.onAssign,
    this.onRefresh, // Add this parameter
  }) : super(key: key);

  @override
  State<MonitorAssignmentDialog> createState() =>
      _MonitorAssignmentDialogState();
}

class _MonitorAssignmentDialogState extends State<MonitorAssignmentDialog> {
  final _firestore = FirebaseFirestore.instance;
  final _isLoading = false.obs;
  final _monitors = <Map<String, dynamic>>[].obs;
  final _selectedMonitorId = ''.obs;

  @override
  void initState() {
    super.initState();
    _fetchMonitors();
    if (widget.currentMonitorId != null) {
      _selectedMonitorId.value = widget.currentMonitorId!;
    }
  }

  Future<void> _fetchMonitors() async {
    _isLoading.value = true;

    try {
      final snapshot = await _firestore.collection('monitors').get();

      _monitors.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'username': data['username'] ?? '',
        };
      }).toList();

      // Sort by name
      _monitors.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load monitors: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assign Monitor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Select a monitor to assign to this site',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),

            const SizedBox(height: 24),

            Obx(() {
              if (_isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (_monitors.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 48,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No monitors available.\nCreate a monitor first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select Monitor',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    value: _selectedMonitorId.value.isEmpty
                        ? null
                        : _selectedMonitorId.value,
                    items: _monitors
                        .map<DropdownMenuItem<String>>(
                          (monitor) => DropdownMenuItem<String>(
                            value: monitor['id'] as String,
                            child: Text(
                              "${monitor['name']} (${monitor['username']})",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectedMonitorId.value = value;
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Assign button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedMonitorId.value.isEmpty
                          ? null
                          : () {
                              widget.onAssign(_selectedMonitorId.value);
                              // Call refresh callback if provided
                              if (widget.onRefresh != null) {
                                widget.onRefresh!();
                              }
                              Get.back();
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Assign Monitor'),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
