import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:be_real/ui/admin/controller/monitors_controller.dart';
import 'package:data_table_2/data_table_2.dart';

class MonitorsScreen extends StatelessWidget {
  const MonitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MonitorsController());

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Search and Refresh Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or phone',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: controller.updateSearch,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: controller.fetchUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Users Table
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.filteredUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 900,
                      columns: const [
                        DataColumn2(
                          label: Text(
                            'Username',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Text(
                            'Full Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Text(
                            'Phone',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Text(
                            'Actions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          size: ColumnSize.L,
                        ),
                      ],
                      rows: List<DataRow>.generate(
                        controller.filteredUsers.length,
                        (index) {
                          final user = controller.filteredUsers[index];

                          final isActive = user['isActive'] ?? true;

                          return DataRow(
                            cells: [
                              DataCell(Text(user['username'] ?? '-')),
                              DataCell(Text(user['name'] ?? '-')),

                              DataCell(Text(user['email'] ?? '-')),
                              DataCell(Text(user['mobile'] ?? '-')),
                              DataCell(
                                Switch(
                                  value: isActive,
                                  onChanged: (value) => controller
                                      .toggleUserStatus(user['id'], isActive),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Edit User',
                                      onPressed: () =>
                                          controller.navigateToEditUser(user),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.password,
                                        color: Colors.orange,
                                      ),
                                      tooltip: 'Reset Password',
                                      onPressed: () => controller.resetPassword(
                                        user['id'],
                                        user['firstName'] ?? '',
                                        user['phone'] ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
