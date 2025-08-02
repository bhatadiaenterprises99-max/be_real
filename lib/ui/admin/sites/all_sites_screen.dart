import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/site_view_controller.dart';
import '../widgets/site_table.dart';

class AllSitesScreen extends StatelessWidget {
  const AllSitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return GetBuilder<SiteViewController>(
      init: SiteViewController(),
      builder: (controller) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Text(
                  'All Sites',
                  style: TextStyle(
                    fontSize: isWide ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View and manage all installation sites',
                  style: TextStyle(
                    fontSize: isWide ? 16 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Filter section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filter options in row or column based on screen width
                        isWide
                            ? Row(
                                children: [
                                  // Company dropdown
                                  Expanded(
                                    child: _buildCompanyDropdown(controller),
                                  ),
                                  const SizedBox(width: 16),
                                  // Search field
                                  Expanded(
                                    child: _buildSearchField(controller),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildCompanyDropdown(controller),
                                  const SizedBox(height: 16),
                                  _buildSearchField(controller),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sites table/list
                Expanded(
                  child: Obx(() {
                    // Show loading state
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sites = controller.filteredSites;

                    // Show empty state
                    if (sites.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sites found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try changing your filters or select another company',
                              style: TextStyle(color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    // Show sites table
                    return SiteTable(
                      sites: sites,
                      getCompanyName: controller.getCompanyName,
                      getStatusColor: controller.getStatusColor,
                      onViewSiteDetails: (siteId) {
                        controller.viewSiteDetails(siteId);
                      },
                      // Add these new parameters
                      getMonitorName: controller.getMonitorName,
                      onAssignMonitor: controller.assignMonitorToSite,
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyDropdown(SiteViewController controller) {
    return Obx(() {
      if (controller.companies.isEmpty) {
        return const SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Select Company',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: const Icon(Icons.business),
        ),
        value: controller.selectedCompanyId.value.isEmpty
            ? null
            : controller.selectedCompanyId.value,
        items: controller.companies.map((company) {
          return DropdownMenuItem<String>(
            value: company['id'],
            child: Text(company['name']),
          );
        }).toList(),
        onChanged: (value) {
          controller.setSelectedCompany(value ?? '');
        },
        hint: const Text('Select a company'),
        isExpanded: true,
      );
    });
  }

  Widget _buildSearchField(SiteViewController controller) {
    return TextField(
      controller: controller.searchController,
      decoration: InputDecoration(
        labelText: 'Search sites',
        hintText: 'Enter location, state, district...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Obx(() {
          // Check if search query is not empty and controller is not disposed
          if (controller.searchQuery.isNotEmpty &&
              controller.searchController != null) {
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                if (controller.searchController != null) {
                  controller.searchController.clear();
                  controller.updateSearch('');
                }
              },
            );
          }
          return const SizedBox.shrink();
        }),
      ),
      onChanged: controller.updateSearch,
    );
  }
}
