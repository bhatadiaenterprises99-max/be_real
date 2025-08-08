import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:be_real/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:be_real/ui/controllers/home_controller.dart';

class MonitorTasksListScreen extends StatelessWidget {
  final String title;
  final String taskType;

  const MonitorTasksListScreen({
    Key? key,
    required this.title,
    required this.taskType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (homeController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sites')
              .where('monitorId', isEqualTo: homeController.monitorId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final tasks = snapshot.data?.docs ?? [];
            final filteredTasks = _filterTasks(tasks, taskType);

            if (filteredTasks.isEmpty) {
              return Center(
                child: Text(
                  'No tasks available',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _buildTaskCard(context, task);
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildTaskCard(BuildContext context, DocumentSnapshot task) {
    final data = task.data() as Map<String, dynamic>;
    final campaignName = data['campaignName'] ?? 'Unknown Campaign';
    final city = data['city'] ?? 'Unknown Location';
    final mediaType = data['mediaType'] ?? 'Not specified';

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.userTasksScreen, arguments: {'taskId': task.id});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaignName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mediaType,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DocumentSnapshot> _filterTasks(
    List<DocumentSnapshot> tasks,
    String type,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case 'today':
        return tasks.where((task) {
          final data = task.data() as Map<String, dynamic>;
          final taskDate = (data['taskDate'] as Timestamp?)?.toDate();
          return taskDate != null &&
              taskDate.year == today.year &&
              taskDate.month == today.month &&
              taskDate.day == today.day;
        }).toList();

      case 'future':
        return tasks.where((task) {
          final data = task.data() as Map<String, dynamic>;
          final taskDate = (data['taskDate'] as Timestamp?)?.toDate();
          return taskDate != null && taskDate.isAfter(today);
        }).toList();

      case 'reported':
        return tasks.where((task) {
          final data = task.data() as Map<String, dynamic>;
          return data['status'] == 'completed';
        }).toList();

      case 'missed':
        return tasks.where((task) {
          final data = task.data() as Map<String, dynamic>;
          return data['status'] == 'expired';
        }).toList();

      case 'to-upload':
        return tasks.where((task) {
          final data = task.data() as Map<String, dynamic>;
          final status = data['status'];
          final uploads = data['monitorUploads'] as Map<String, dynamic>? ?? {};
          final images = uploads['images'] as List? ?? [];

          return (status == 'pending' || status == 'ongoing') && images.isEmpty;
        }).toList();

      default:
        return tasks;
    }
  }
}
