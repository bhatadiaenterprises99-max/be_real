import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:be_real/ui/controllers/task_controller.dart';
import 'package:be_real/ui/mobile/upload_media_screen.dart';
import 'package:be_real/widgets/common_button.dart';

class UserTasksScreen extends StatefulWidget {
  const UserTasksScreen({super.key});

  @override
  State<UserTasksScreen> createState() => _UserTasksScreenState();
}

class _UserTasksScreenState extends State<UserTasksScreen> {
  late TaskController taskController;

  @override
  void initState() {
    super.initState();
    taskController = Get.put(TaskController());
    taskController.loadMonitorSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Modern header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Assigned Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // List of assigned sites
            Expanded(
              child: Obx(() {
                if (taskController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (taskController.hasError.value) {
                  return Center(
                    child: Text(
                      taskController.errorMessage.value,
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  );
                }

                if (taskController.assignedSites.isEmpty) {
                  return Center(
                    child: Text(
                      'No assigned sites found',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: taskController.assignedSites.length,
                  itemBuilder: (context, index) {
                    final site = taskController.assignedSites[index];
                    final siteId = site['id'] as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Media preview
                          _buildMediaPreview(siteId),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Company header
                                Text(
                                  'Company',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        taskController.getCompanyValue('name'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          siteId,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getStatusText(siteId),
                                        style: GoogleFonts.poppins(
                                          color: _getStatusColor(siteId),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Site Information
                                Text(
                                  'Site Information',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  children: [
                                    _buildDetailItem(
                                      'State',
                                      taskController.getSiteValue(
                                        siteId,
                                        'state',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                      'District',
                                      taskController.getSiteValue(
                                        siteId,
                                        'district',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                      'City/Town',
                                      taskController.getSiteValue(
                                        siteId,
                                        'cityTown',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                      'Media type',
                                      taskController.getSiteValue(
                                        siteId,
                                        'media',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                      'Location',
                                      taskController.getSiteValue(
                                        siteId,
                                        'location',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                      'Type',
                                      taskController.getSiteValue(
                                        siteId,
                                        'type',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                      'Units',
                                      taskController.getSiteValue(
                                        siteId,
                                        'units',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                      'Width × Height',
                                      '${taskController.getSiteValue(siteId, 'width')} × ${taskController.getSiteValue(siteId, 'height')}',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLocationItem(),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Company Details
                                Text(
                                  'Company Details',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildDetailItem(
                                  'Contact Person',
                                  taskController.getSiteValue(
                                    siteId,
                                    'companyContactPerson',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailItem(
                                  'Contact Number',
                                  taskController.getSiteValue(
                                    siteId,
                                    'companyContactNumber',
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Action button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Extract site ID from task data

                                      final siteName = taskController.getValue(
                                        'location',
                                      );

                                      Get.to(
                                        () => UploadMediaScreen(
                                          siteId: siteId,
                                          siteName: siteName,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C63FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.camera_alt_rounded),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Take Picture',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(String siteId) {
    final mediaUrls = taskController.getSiteMediaUrls(siteId);

    if (mediaUrls.isNotEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          image: DecorationImage(
            image: NetworkImage(mediaUrls.first),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Media Preview', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String siteId) {
    final status = taskController.getSiteStatus(siteId);
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'ongoing':
        return const Color(0xFF6C63FF);
      case 'expired':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String siteId) {
    final status = taskController.getSiteStatus(siteId);
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'ongoing':
        return 'Active';
      case 'expired':
        return 'Expired';
      default:
        return 'Pending';
    }
  }

  Widget _buildDetailItem(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          ":",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location :',
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'View on map',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: Color(0xFF6C63FF),
          ),
        ),
      ],
    );
  }
}
